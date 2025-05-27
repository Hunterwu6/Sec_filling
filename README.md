# SEC Filings Monitoring Dashboard

## Project Overview

During peak reporting seasons, analysts often struggle to keep up with the sheer volume of SEC filings. Critical information can be missed when relying on manual monitoring of the SEC’s EDGAR system. This project addresses that challenge by providing a real-time monitoring pipeline for SEC filings. Leveraging a serverless architecture on Google Cloud Platform (GCP), the system automatically collects new filings from the SEC's EDGAR RSS feed, processes and stores key filing data, and presents it through an interactive dashboard. The result is a lightweight, cost-efficient solution that delivers near real-time updates with minimal human intervention.

## Architecture

The SEC Filings Monitoring Dashboard is built using several GCP services in a serverless, event-driven pipeline. Each component of the architecture plays a specific role in the end-to-end flow:

* **Data Source – SEC EDGAR RSS Feed**: The publicly available EDGAR RSS feed provides a live stream of newly submitted SEC filings in XML format. Each feed entry includes metadata such as the filing time, form type (e.g., 10-K, 10-Q, 8-K), company name, CIK, and a link to the filing document.
* **Cloud Scheduler**: A managed cron-like service that triggers the pipeline at regular intervals (e.g., every 10 minutes). The Cloud Scheduler job publishes a message to a designated Pub/Sub topic to initiate the ingestion process on schedule.
* **Cloud Pub/Sub**: A messaging service that decouples event publishing from processing. The Cloud Scheduler’s message is sent to a Pub/Sub topic, which ensures reliable delivery and can buffer triggers if needed. This setup increases resiliency – if the processing function is momentarily unavailable, the message will be retained until it can be handled.
* **Cloud Functions**: A serverless Python function is subscribed to the Pub/Sub topic. When a new message arrives (i.e., on the schedule), the function wakes up and runs the ingestion logic. It fetches the latest entries from the EDGAR RSS feed, parses each filing’s metadata (such as company, form type, date, accession number, etc.), and writes the structured data into BigQuery. Using Cloud Functions keeps the solution lightweight, scaling automatically with load and only running on demand.
* **BigQuery**: A serverless data warehouse that stores the collected filings data in a table. Each record corresponds to a filing and includes fields like filing date, company name, form type, CIK, accession number, and the URL to the full filing. BigQuery’s SQL capabilities allow for easy querying, filtering, and aggregation of the filings data for analysis.
* **Looker Studio Dashboard**: Google’s Looker Studio (formerly Data Studio) is used as the visualization layer. It connects directly to the BigQuery dataset to provide a real-time dashboard. Users can interact with filters (date range, form type, company name, etc.), view summary statistics, and explore charts or tables of recent filings and trends.

*The diagram below illustrates the data flow from the SEC feed through GCP to the dashboard.*

```
              Cloud Scheduler (cron job, every 5 min)
                         |
        (triggers)       v
        Pub/Sub Topic "sec-filings-topic" :contentReference[oaicite:0]{index=0}
                         |
        (pushes event)   v
        Cloud Run (Ingestion Service) :contentReference[oaicite:1]{index=1}
            - Fetches latest EDGAR RSS feed entries
            - Parses filings and writes to BigQuery :contentReference[oaicite:2]{index=2}
                         |
                         v
              BigQuery (sec_filings table) :contentReference[oaicite:3]{index=3}:contentReference[oaicite:4]{index=4}
                         |
                         v
              Looker Studio Dashboard (interactive charts)
                         ^
                         |
        Cloud Run (Backfill Service) :contentReference[oaicite:5]{index=5}
            - On-demand HTTP trigger (with ?year & quarter)
            - Fetches historical EDGAR index data:contentReference[oaicite:6]{index=6}
            - Loads past filings into BigQuery

```

## Features

The SEC Filings Monitoring Dashboard offers the following key features:

* **Real-Time Ingestion**: New SEC filings are captured and ingested into the system within minutes of their release. This near real-time pipeline ensures that analysts have access to the most recent filings without manual effort.
* **Interactive Filtering and Search**: The dashboard allows users to filter filings by form type (10-K, 10-Q, 8-K, etc.), filing date ranges, and company name. This makes it easy to drill down to specific filings of interest. Keyword tagging is implemented for certain high-impact terms (e.g., "restatement", "material weakness", "going concern"), helping highlight filings that may signal potential red flags or important events.
* **Automated Analytics**: The Looker Studio dashboard provides built-in analytics on the filings data. It displays summary metrics (total filings, filings by type), visualizes trends over time (such as filings per day or per week), and highlights top filing companies in the selected period. These visualizations turn the raw stream of filings into actionable insights at a glance.
* **Scalable & Serverless Architecture**: The entire system runs on serverless services (Cloud Functions, Pub/Sub, BigQuery), which automatically scale to handle large bursts of filings (such as quarter-end peaks) without any manual scaling. There are no servers to manage, and costs remain low as you pay only for resources used during actual filing processing.

## Google Cloud Setup Instructions

To deploy this project in your own Google Cloud environment, you will need to configure several GCP services and resources. Below is a step-by-step guide:

1. **Enable Required APIs**: Ensure that the Cloud Functions, Cloud Pub/Sub, Cloud Scheduler, and BigQuery APIs are enabled in your GCP project.
2. **BigQuery Setup**: Create a BigQuery dataset (e.g., `sec_data`) for this project. Within that dataset, create a table (e.g., `filings`) with the schema outlined in the next section. You can do this via the BigQuery Console or using the `bq` command-line tool.
3. **Cloud Pub/Sub**: Create a Pub/Sub topic (e.g., `sec-filings-topic`). This topic will be used by Cloud Scheduler to trigger the Cloud Function. No subscriptions need to be manually created, as the Cloud Function deployment will handle that.
4. **Cloud Function**: Deploy the Cloud Function code (provided in this repository) to GCP. This function should be set to trigger from the Pub/Sub topic created above. You can deploy via the Cloud Console or using the gcloud CLI (see Deployment steps below). Make sure the function's service account has permission to write to BigQuery (e.g., assign the BigQuery Data Editor role). Update any necessary environment variables or configuration so the function knows the BigQuery dataset and table names.
5. **Cloud Scheduler**: Set up a Cloud Scheduler job to run at the desired frequency (e.g., every 10 minutes) and publish a message to the Pub/Sub topic. This scheduled trigger ensures the pipeline runs continuously, fetching new filings as they appear.

## Deployment

For convenience, here are example gcloud commands corresponding to the setup steps above. Run these in the gcloud CLI, replacing placeholders with your actual project IDs, dataset names, and file paths:

```bash
# 1. Create a Pub/Sub topic for the SEC filings feed
gcloud pubsub topics create sec-filings-topic

# 2. Create a BigQuery dataset and table (if not already created)
bq mk -d my_project:sec_data
bq mk -t sec_data.filings filing_date:DATE,company_name:STRING,form_type:STRING,cik:STRING,accession_number:STRING,filing_url:STRING

# 3. Deploy the Cloud Function to ingest filings (ensure you are in the function code directory)
gcloud functions deploy sec-ingest-func \
    --runtime python39 \
    --trigger-topic sec-filings-topic \
    --memory 128MB \
    --set-env-vars DATASET=sec_data,TABLE=filings \
    --entry-point YOUR_FUNCTION_NAME \
    --project YOUR_PROJECT_ID

# 4. Create a Cloud Scheduler job to trigger the Pub/Sub topic every 10 minutes
gcloud scheduler jobs create pubsub sec-filings-schedule \
    --schedule="*/10 * * * *" \
    --topic=sec-filings-topic \
    --message-body="{}"
```

## BigQuery Schema

The BigQuery table stores each filing record with the following fields:

* **filing\_date** (DATE): The date the filing was submitted to the SEC (YYYY-MM-DD).
* **company\_name** (STRING): The name of the company submitting the filing.
* **form\_type** (STRING): The SEC form type (e.g., 10-K, 10-Q, 8-K, etc.).
* **cik** (STRING): The SEC Central Index Key identifying the company (as a string, including leading zeros).
* **accession\_number** (STRING): The unique accession number of the filing, which can be used to retrieve the document from the SEC.
* **filing\_url** (STRING): The direct URL link to the filing document or summary on the SEC’s EDGAR system.

Having the data in a structured format allows for flexible querying. For example, users can write SQL queries in BigQuery to filter filings by date or company, count filings by form type over time, or perform other analyses to derive insights from the filings dataset.

## Dashboard

The interactive dashboard is built with **Google Looker Studio**, which directly queries the BigQuery data to visualize filing activity. The dashboard provides:

* **Live Updates**: As new filings land in BigQuery, the charts and tables update to reflect the latest data (with only a brief lag from ingestion).
* **Summary Metrics**: At a glance, see the total number of filings over a period and breakdown by form type (e.g., how many 10-Ks, 8-Ks, etc.).
* **Trends Over Time**: Line charts show the volume of filings per day, helping identify spikes (e.g., quarter-end or specific events) and lulls (e.g., weekends, holidays).
* **Top Filers**: Tables list companies with the most filings in the selected time frame, which can indicate companies undergoing significant events or frequent disclosures.
* **Flexible Filtering**: Controls at the top of the dashboard let users adjust the date range, select specific form types, or focus on particular companies. This interactivity enables drilling down into the data for custom analysis.

To view the live dashboard, visit the \[Dashboard Link]. (You may need a Google account for access if the dashboard is restricted.) The dashboard can be copied or modified as needed to suit different analysis goals. Below is an example screenshot of the dashboard interface:
![Dashboard Screenshot](dashboard_sample.png)

The example above shows a week of filings with various form types, a pie chart breakdown by form, a trendline of daily filings, and the top companies by number of filings. The actual dashboard is interactive, allowing you to click on segments or filter controls to dynamically update the view.

## Future Enhancements

While the current system fulfills its core mission, there are several enhancements that could make it even more powerful:

* **Industry Classification & Filtering**: Integrate industry sector tags (e.g., via NAICS or SIC codes) for each company. This would allow users to filter and compare filings across industries, which is useful for peer analysis or sector-specific monitoring.
* **Alerting & Notifications**: Implement an alert system (email or SMS) to notify analysts of new filings that meet certain criteria (for example, if a watched company files an 8-K, or if a filing contains specific keywords). This would push critical updates proactively to users.
* **Enhanced Text Analysis**: Ingest more detailed data from filings (such as summaries or full text) to enable keyword searches and possibly sentiment or anomaly detection on filing content. This could help flag unusual disclosures or risk factors automatically.
* **Custom Front-end**: Eventually, develop a dedicated web application for the dashboard to provide more customization and possibly integrate authentication, saving user preferences, and integrating data from other sources. This could complement or replace the Looker Studio interface for a more tailored user experience.

These ideas leverage the existing pipeline – because the data is already centralized in BigQuery, additional processing or outputs (like an alerting Cloud Function or an ML model for analysis) can be added without disrupting the current system. Future improvements will be guided by user feedback and emerging requirements in financial data monitoring.

## License

This project is open source and is made available under the terms of the \[LICENSE]. Please see the license file for details on usage and redistribution.

## Acknowledgments

This project was originally developed as a capstone for an **Enterprise Cloud Computing and Big Data** course. We thank our instructor and teaching assistants for their guidance, as well as the SEC for providing open access to the EDGAR filings feed. We also acknowledge Google Cloud's free tier, which allowed us to build and test this system cost-effectively.
