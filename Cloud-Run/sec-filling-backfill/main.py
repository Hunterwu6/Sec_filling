# main.py

import os
import re
import logging
import requests
import functions_framework
from google.cloud import bigquery
from flask import jsonify  # we can still use Flask's jsonify

# ─── CONFIG & CLIENT ───────────────────────────────────────────────────────────

# user-agent header — please replace with your own
SEC_USER_AGENT = os.getenv(
    "SEC_USER_AGENT",
    "SEC-Backfill/1.0 (hunterwuwork@gmail.com)"
)

# BigQuery table to write to (project.dataset.table)
BQ_TABLE_ID = os.getenv(
    "BQ_TABLE_ID",
    "sec-filling.sec_filings.sec_filings"
)

# base URL for EDGAR full-index files
BASE_IDX_URL = "https://www.sec.gov/Archives/edgar/full-index"

# BigQuery client (will pick up your service-account creds automatically)
bq = bigquery.Client()

# configure root logger
logging.basicConfig(level=logging.INFO)


# ─── HELPERS ────────────────────────────────────────────────────────────────────

def fetch_and_parse(year: str, quarter: str) -> list[dict]:
    """Download and parse master.idx for a single quarter into a list of dicts."""
    url = f"{BASE_IDX_URL}/{year}/QTR{quarter}/master.idx"
    logging.info("Fetching %s QTR%s …", year, quarter)
    resp = requests.get(
        url,
        headers={"User-Agent": SEC_USER_AGENT},
        timeout=60
    )
    resp.raise_for_status()

    # skip the first 10 header lines
    lines = resp.text.splitlines()[10:]
    parsed = []

    for line in lines:
        parts = line.split("|")
        if len(parts) != 5:
            continue
        cik, comp, form, date_, path = parts
        m = re.search(r"edgar/data/\d+/([^/]+)\.txt$", path)
        if not m:
            continue

        parsed.append({
            "cik":              cik,
            "company_name":     comp,
            "form_type":        form,
            "filing_date":      date_,
            "accession_number": m.group(1),
            "filing_url":       f"https://www.sec.gov/Archives/{path}",
        })

    logging.info("Parsed %d rows", len(parsed))
    return parsed


def dedupe(records: list[dict]) -> list[dict]:
    """Deduplicate on accession_number (keep first occurrence)."""
    out = {}
    for r in records:
        acc = r["accession_number"]
        if acc and acc not in out:
            out[acc] = r
    return list(out.values())


def insert_in_batches(table_id: str, rows: list[dict], batch_size: int = 500) -> int:
    """
    Insert rows into BigQuery in manageable batches.
    Returns total rows successfully inserted.
    """
    inserted = 0
    for start in range(0, len(rows), batch_size):
        batch = rows[start : start + batch_size]
        errors = bq.insert_rows_json(table_id, batch)
        if errors:
            logging.error("BigQuery insert errors (rows %d–%d): %s",
                          start, start + len(batch), errors)
            raise RuntimeError(f"BigQuery insert failed: {errors}")
        logging.info("Inserted rows %d–%d (count=%d)",
                     start, start + len(batch), len(batch))
        inserted += len(batch)
    return inserted


# ─── ENTRY POINT ────────────────────────────────────────────────────────────────

@functions_framework.http
def run_quarter(request):
    """
    HTTP function entrypoint.
    Query-string parameters: ?year=YYYY&quarter=1|2|3|4

    1) fetch & parse
    2) dedupe
    3) filter out existing in BQ
    4) insert new in batches
    """
    qs = request.args
    year = qs.get("year")
    quarter = qs.get("quarter")

    if not year or quarter not in {"1","2","3","4"}:
        return jsonify({
            "error": "must specify ?year=YYYY&quarter=1|2|3|4"
        }), 400

    # ─── 1) FETCH & PARSE ─────────────────────────────
    try:
        recs = fetch_and_parse(year, quarter)
    except Exception as e:
        logging.exception("Fetch/parse failed")
        return jsonify({"error": str(e)}), 500

    # ─── 2) DEDUPE ────────────────────────────────────
    unique = dedupe(recs)

    # ─── 3) CHECK EXISTING ───────────────────────────
    accs = [r["accession_number"] for r in unique]
    if accs:
        sql = f"""
        SELECT accession_number
        FROM `{BQ_TABLE_ID}`
        WHERE accession_number IN UNNEST(@list)
        """
        job = bq.query(
            sql,
            job_config=bigquery.QueryJobConfig(
                query_parameters=[
                    bigquery.ArrayQueryParameter("list", "STRING", accs)
                ]
            )
        )
        existing = {row["accession_number"] for row in job}
        to_insert = [r for r in unique if r["accession_number"] not in existing]
    else:
        to_insert = []

    # ─── 4) INSERT ─────────────────────────────────────
    inserted = 0
    if to_insert:
        try:
            inserted = insert_in_batches(BQ_TABLE_ID, to_insert, batch_size=500)
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    logging.info("Done %s QTR%s → parsed=%d unique=%d inserted=%d",
                 year, quarter, len(recs), len(unique), inserted)

    return jsonify({
        "year":     year,
        "quarter":  quarter,
        "parsed":   len(recs),
        "unique":   len(unique),
        "inserted": inserted,
    }), 200
