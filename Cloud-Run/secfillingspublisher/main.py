# main.py

import os
import re
import logging
import requests
import xml.etree.ElementTree as ET
from datetime import datetime

from flask import jsonify, make_response, request
import functions_framework
from google.cloud import bigquery

# ─── CONFIG & CLIENT ────────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO)

# BigQuery table to read/write (project.dataset.table)
BQ_TABLE_ID = os.getenv(
    "BQ_TABLE_ID",
    "sec-filling.sec_filings.sec_filings"
)

# SEC EDGAR “current” Atom feed
SEC_USER_AGENT = os.getenv(
    "SEC_USER_AGENT",
    "MySecMonitor/1.0 (hunterwuwork@gmail.com)"
)
FEED_URL = (
    "https://www.sec.gov/cgi-bin/browse-edgar"
    "?action=getcurrent&count=200&output=atom"
)

# BigQuery client (uses service account in Cloud Run/Functions)
bq = bigquery.Client()


# ─── HELPERS ─────────────────────────────────────────────────────────────

def strip_namespaces(root):
    for el in root.iter():
        if isinstance(el.tag, str) and el.tag.startswith("{"):
            el.tag = el.tag.split("}", 1)[1]

def fetch_feed_entries() -> list[ET.Element]:
    """GET the Atom feed and return a list of <entry> elements."""
    resp = requests.get(FEED_URL,
                        headers={"User-Agent": SEC_USER_AGENT},
                        timeout=30)
    resp.raise_for_status()
    root = ET.fromstring(resp.text)
    strip_namespaces(root)
    entries = root.findall(".//entry")
    logging.info("Fetched %d feed entries", len(entries))
    return entries

def parse_entry(e):
    # 1) pull the “alternate” link
    link = e.find("link[@rel='alternate']")
    href = link.get("href","") if link is not None else ""

    # 2) extract CIK & accession exactly as you already have it…
    m = re.search(r"/edgar/data/(\d+)/\d+/([^/]+)-index\.htm", href)
    if m:
        cik, acc = m.group(1), m.group(2)
    else:
        summary = (e.findtext("summary","") or "").replace("\n"," ")
        m2 = re.search(r"AccNo:\s*([0-9\-]+)", summary)
        if not m2:
            return None
        cik, acc = None, m2.group(1)

    # 3) extract form_type
    form_type = ""
    for cat in e.findall("category"):
        if cat.get("label","").lower() == "form type":
            form_type = cat.get("term","")
            break

    # 4) grab raw title, e.g. "4 - Colon Flor (000200009) (Reporting)"
    raw_title = (e.findtext("title","") or "").strip()

    # 5) strip off **any** trailing "(…)" by splitting on the first " ("
    #    this gives "4 - Colon Flor"
    title_no_suffix = raw_title.split(" (")[0]

    # 6) drop the leading "FORM - " if it’s there
    prefix = f"{form_type} - "
    if form_type and title_no_suffix.startswith(prefix):
        company = title_no_suffix[len(prefix):].strip()
    else:
        company = title_no_suffix

    # 7) parse the date
    upd = e.findtext("updated","")
    try:
        filing_date = datetime.fromisoformat(upd).date().isoformat()
    except Exception:
        summary = (e.findtext("summary","") or "").replace("\n"," ")
        m3 = re.search(r"Filed:\s*([0-9]{4}-[0-9]{2}-[0-9]{2})", summary)
        filing_date = m3.group(1) if m3 else None

    return {
        "cik":               cik,
        "company_name":      company,
        "form_type":         form_type,
        "filing_date":       filing_date,
        "accession_number":  acc,
        "filing_url":        href,
    }

def dedupe(rows: list[dict]) -> list[dict]:
    """Keep only the first occurrence of each accession_number."""
    seen = {}
    for r in rows:
        key = r["accession_number"]
        if key and key not in seen:
            seen[key] = r
    return list(seen.values())

def filter_existing(rows: list[dict]) -> list[dict]:
    """Remove any rows whose accession_number already exists in BigQuery."""
    if not rows:
        return []
    accs = [r["accession_number"] for r in rows]
    sql = f"""
      SELECT accession_number
      FROM `{BQ_TABLE_ID}`
      WHERE accession_number IN UNNEST(@list)
    """
    job = bq.query(
        sql,
        job_config=bigquery.QueryJobConfig(
            query_parameters=[
                bigquery.ArrayQueryParameter("list","STRING",accs)
            ]
        )
    )
    existing = {row["accession_number"] for row in job}
    return [r for r in rows if r["accession_number"] not in existing]

def insert_rows(rows: list[dict]) -> int:
    """Stream-insert up to len(rows) into BigQuery; returns count inserted."""
    if not rows:
        return 0
    errors = bq.insert_rows_json(BQ_TABLE_ID, rows)
    if errors:
        for e in errors:
            logging.error("BQ insert error: %s", e)
        raise RuntimeError("BigQuery insert failed")
    return len(rows)

def query_filings(limit: int | None = None) -> list[dict]:
    """SELECT the most recent filings from BigQuery (optionally limited)."""
    sql = f"""
      SELECT
        accession_number, company_name, form_type,
        filing_date, filing_url, cik
      FROM `{BQ_TABLE_ID}`
      ORDER BY filing_date DESC
    """
    params = []
    if limit is not None:
        sql += "\nLIMIT @lim"
        params.append(bigquery.ScalarQueryParameter("lim","INT64",limit))
    job = bq.query(
        sql,
        job_config=bigquery.QueryJobConfig(query_parameters=params)
    )
    return [dict(row) for row in job]


# ─── FUNCTION ENTRYPOINT ───────────────────────────────────────────────────

@functions_framework.http
def main(request):
    # CORS preflight
    if request.method == "OPTIONS":
        return ("", 204, {
            "Access-Control-Allow-Origin":  "*",
            "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        })

    # GET → return JSON list of recent filings
    if request.method == "GET":
        try:
            limit = request.args.get("limit")
            results = query_filings(int(limit)) if limit else query_filings()
        except Exception as e:
            logging.exception("BigQuery query failed")
            return jsonify({"error": str(e)}), 500
        resp = make_response(jsonify(results), 200)
        resp.headers["Access-Control-Allow-Origin"] = "*"
        return resp

    # POST → fetch the live Atom feed, parse & insert new filings
    if request.method == "POST":
        try:
            entries = fetch_feed_entries()
            parsed  = [p for e in entries if (p:=parse_entry(e))]
            logging.info("Parsed %d filings", len(parsed))

            unique  = dedupe(parsed)
            logging.info("%d after dedupe", len(unique))

            to_insert = filter_existing(unique)
            logging.info("%d new to insert", len(to_insert))

            n = insert_rows(to_insert)
            logging.info("Inserted %d rows", n)

            resp = make_response(jsonify({"inserted": n}), 200)
            resp.headers["Access-Control-Allow-Origin"] = "*"
            return resp

        except Exception as e:
            logging.exception("Ingestion failed")
            return jsonify({"error": str(e)}), 500

    # Method not allowed
    return jsonify({"error":"Only GET and POST supported"}), 405
