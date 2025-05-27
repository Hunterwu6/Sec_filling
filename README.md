# Sec_filling – Real-Time SEC Filings Monitoring System

## Project Overview 
Tracking SEC filings manually on the EDGAR website can be tedious and inefficient. **Sec_filling** is a real-time monitoring pipeline that automates ingestion and tracking of company filings using Google Cloud’s serverless services. It checks for new filings on the SEC EDGAR feed at frequent intervals and loads them into BigQuery for easy querying and analysis. An interactive Looker Studio dashboard provides visualizations of key metrics and trends.  

## System Architecture Diagram :
![Architecture Diagram]
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
