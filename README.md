# Sec_filling – Real-Time SEC Filings Monitoring System

## Project Overview 
Tracking SEC filings manually on the EDGAR website can be tedious and inefficient. **Sec_filling** is a real-time monitoring pipeline that automates ingestion and tracking of company filings using Google Cloud’s serverless services. It checks for new filings on the SEC EDGAR feed at frequent intervals and loads them into BigQuery for easy querying and analysis. An interactive Looker Studio dashboard provides visualizations of key metrics and trends.  

## System Architecture Diagram :
```text
Cloud Scheduler (every 5 min)
        ↓
Pub/Sub Topic "sec-filings-topic"
        ↓
Cloud Run (Ingestion Service)
  • Fetch & parse EDGAR RSS feed
  • Write new filings to BigQuery
        ↓
BigQuery (sec_filings table)
        ↓
Looker Studio Dashboard
        ↑
Cloud Run (Backfill Service)
  • On-demand HTTP trigger (?year & quarter)
  • Fetch historical index & load to BigQuery
```text

## Features
 •Real-Time Ingestion: Pulls the latest filings from the SEC’s EDGAR Atom feed (up to ~200 entries at a time) and ingests them automatically.

 •Scheduled Updates: A Cloud Scheduler cron job runs every 5 minutes, publishing to Pub/Sub to trigger the ingestion service with minimal compute usage.

 •Historical Backfill: A separate Cloud Run service that fetches and loads historical filings by year and quarter, handling large index files and avoiding duplicates.

 •BigQuery Data Warehouse: Stores all parsed filings in a sec_filings table with de-duplication by accession number, enabling scalable SQL querying.

 •Interactive Dashboard: A Looker Studio dashboard with KPI cards, bar charts, and time series graphs, updated automatically as new data arrives.

## Google Cloud Setup
 •Enable APIs
```text
gcloud services enable \
  run.googleapis.com \
  pubsub.googleapis.com \
  cloudscheduler.googleapis.com \
  bigquery.googleapis.com \
  cloudbuild.googleapis.com
