# Sec_filling – Real-Time SEC Filings Monitoring

# System

## Project Overview

Tracking SEC filings manually on the EDGAR website can be tedious and inefficient. **Sec_filling** is a real-time
SEC filings monitoring pipeline that automates the ingestion and tracking of company filings using Google
Cloud’s serverless services. The system checks for new filings on the SEC EDGAR feed at frequent intervals
and loads them into a BigQuery data warehouse for easy querying and analysis. An interactive dashboard
built with Looker Studio provides visualization of key metrics and trends. The architecture is fully **serverless**

- using Cloud Scheduler to trigger ingestion, Pub/Sub to distribute events, Cloud Run services to fetch and
process filings, and BigQuery to store the results – ensuring a scalable and low-maintenance solution.

## System Architecture Diagram

Below is a high-level architecture diagram illustrating the data flow from the SEC EDGAR feed through the
GCP services to the final dashboard:

```
Cloud Scheduler (every 5 min)
↓
Pub/Sub Topic: sec-filings-topic
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
  • On-demand HTTP trigger (year & quarter)
  • Fetch historical index & load to BigQuery
```
## Features

•Real-Time Ingestion of Filings: The system pulls the latest filings from the SEC’s EDGAR Atom feed
(up to ~200 at a time) in near real-time. New EDGAR entries are detected and ingested
automatically, so you no longer have to manually monitor the SEC website.

•Real-Time Ingestion of Filings: The system pulls the latest filings from the SEC’s EDGAR Atom feed
Frequent Scheduled Updates (5-minute Interval): A Cloud Scheduler cron job runs every 5
minutes (configurable) and publishes a message to a Pub/Sub topic. This triggers the Cloud Run
ingestion service via Pub/Sub, ensuring new filings are fetched and processed almost immediately
after they appear on EDGAR. The decoupling via Pub/Sub means the ingestion service only runs
when triggered , minimizing compute usage.

•Real-Time Ingestion of Filings: The system pulls the latest filings from the SEC’s EDGAR Atom feed
Historical Backfill Function: In addition to live monitoring, a separate Cloud Run service can
backfill historical filings. By specifying a year and quarter, this service fetches the SEC master
index for that period and loads all filings from that timeframe into BigQuery. This is useful for
seeding the database with past data (e.g., last quarter’s or last year’s filings) so the dashboard has
historical context. The backfill function handles large index files by parsing and batching inserts,
while avoiding duplicate entries.

•Real-Time Ingestion of Filings: The system pulls the latest filings from the SEC’s EDGAR Atom feed
BigQuery Data Warehouse: All parsed filing records are stored in a BigQuery table
(sec_filings). Using BigQuery provides scalable storage and the ability to query filings data with
SQL. The ingestion pipeline ensures no duplicate filings are inserted (checking by unique accession
number) , and BigQuery’s fast querying enables interactive analysis on the dashboard.

•Real-Time Ingestion of Filings: The system pulls the latest filings from the SEC’s EDGAR Atom feed
Interactive Dashboard (Looker Studio): A pre-built Looker Studio dashboard connects directly to
the BigQuery dataset. It includes KPI summary cards (e.g. total number of filings, filings this week),
bar charts (e.g. number of filings by form type or by company), and line graphs (filings over time) to
help visualize trends. The dashboard updates automatically as new data flows into BigQuery,
allowing users to monitor filings in real-time. You can filter or drill down by form type, company, or
date to find filings of interest. (If a Looker Studio report template is available, you can use it by
connecting it to your BigQuery data source. Otherwise, you can create a new report in Looker Studio, add
BigQuery as a data source, and use the sec_filings table to build charts.)

## Google Cloud Setup Instructions

To deploy this project, you will need a Google Cloud project with the appropriate services enabled and
resources created. Follow these setup steps:

•Enable APIs: Ensure the required GCP APIs are active in your project. At minimum, enable the Cloud
Run API , Cloud Pub/Sub API , Cloud Scheduler API , and BigQuery API (as well as the Cloud Build
API if deploying via source). This can be done via the Cloud Console or with gcloud commands, for
example:
```
gcloud services enable run.googleapis.com pubsub.googleapis.com \
    cloudscheduler.googleapis.com bigquery.googleapis.com
```
•Create Pub/Sub Topic: Create a Pub/Sub topic that will carry trigger messages for new filings ingestion. The system assumes a topic named sec-filings-topic. You can create it in the Cloud Console or via gcloud:
```
gcloud pubsub topics create sec-filings-topic
```
•Set Up BigQuery Dataset and Table: In BigQuery, create a dataset (e.g. named sec_filings) and within it create a table sec_filings with the schema below (see BigQuery Schema section). The table should have fields for filing date, company name, form type, CIK, accession number, and filing URL.
You can create the table via the BigQuery web UI or with the bq command-line tool. For example, to create a dataset:
```
bq --location=US mk -d your-project-id:sec_filings 
```
And to create the table with the proper schema (assuming you saved the schema JSON):
```
bq mk -t --schema=bq-sec_filings-schema.json your-project-id:sec_filings.sec_filings 
```
Ensure the table schema matches the expected fields (order doesn’t matter as long as names/types match).

### Service Accounts and IAM Permissions: 
Set up necessary IAM roles for seamless communication:
.BigQuery Access: The Cloud Run services (ingestion and backfill) will use the default compute service account (or a specified service account) to insert into BigQuery. Grant that service account BigQuery Data Editor (or at least BigQuery Dataset Writer) permissions on your project or specifically on the dataset. For example, if using the default service account, grant roles/bigquery.dataEditor to YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com
.Cloud Run Invoker (for Pub/Sub): If you plan to secure Cloud Run (disallow public access), you need to permit Pub/Sub to trigger the ingestion service. Create a Pub/Sub push subscription (in Deployment steps below) that uses a service account. Then grant that service account the Cloud Run Invoker role on the ingestion Cloud Run service. This ensures Pub/Sub messages can invoke the Cloud Run endpoint. (If you choose to allow unauthenticated invocations for simplicity, you can skip this, but restricting access is recommended.)
.Cloud Scheduler Permissions: By default, Cloud Scheduler uses the App Engine default service account to publish to Pub/Sub. Make sure that account has Pub/Sub Publisher rights on the sec-filings-topic. This is usually YOUR_PROJECT_ID@appspot.gserviceaccount.com. You can add the role roles/pubsub.publisher for that service account on the topic if it’s not already present.

### Configure Environment Variables: 
Decide on values for environment variables needed by the services:
```BQ_TABLE_ID``` – This tells the Cloud Run code which BigQuery table to write to. It should be set to your-project-id.sec_filings.sec_filings (i.e., project.dataset.table). By default the code expects sec-filling.sec_filings.sec_filings, but you should override it with your project/dataset.
```SEC_USER_AGENT``` – The SEC requires a custom User-Agent string for automation. Set this to identify your application (e.g., "MySecMonitor/1.0 (your-email@example.com)" as shown in the code). This is used in HTTP requests to EDGAR so that your script abides by SEC’s fair use policy.
You will provide these env vars during Cloud Run deployment (using --set-env-vars in gcloud or via the Cloud Run console UI).
With the infrastructure in place and the above configured, you’re ready to deploy the Cloud Run services and set up the data pipeline.




gcloud servicesenable run.googleapis.com pubsub.googleapis.com\
cloudscheduler.googleapis.combigquery.googleapis.com
```
```
Create Pub/Sub Topic: Create a Pub/Sub topic that will carry trigger messages for new filings
ingestion. The system assumes a topic named sec-filings-topic. You can create it in the Cloud
Console or via gcloud:
```
```
gcloud pubsubtopics create sec-filings-topic
```
```
Set Up BigQuery Dataset and Table: In BigQuery, create a dataset (e.g. named sec_filings )
and within it create a table sec_filings with the schema below (see BigQuery Schema section).
The table should have fields for filing date, company name, form type, CIK, accession number, and
filing URL. You can create the table via the BigQuery web UI or with the bq command-line
tool. For example, to create a dataset:
```
```
bq --location=US mk -d your-project-id:sec_filings
```
And to create the table with the proper schema (assuming you saved the schema JSON):

```
bq mk -t --schema=bq-sec_filings-schema.jsonyour-project-
id:sec_filings.sec_filings
```
Ensure the table schema matches the expected fields (order doesn’t matter as long as names/types match).

```
Service Accounts and IAM Permissions: Set up necessary IAM roles for seamless communication:
BigQuery Access: The Cloud Run services (ingestion and backfill) will use the default compute service
account (or a specified service account) to insert into BigQuery. Grant that service account BigQuery
Data Editor (or at least BigQuery Dataset Writer) permissions on your project or specifically on the
dataset. For example, if using the default service account, grant roles/bigquery.dataEditor to
YOUR_PROJECT_NUMBER-compute@developer.gserviceaccount.com.
Cloud Run Invoker (for Pub/Sub): If you plan to secure Cloud Run (disallow public access), you need to
permit Pub/Sub to trigger the ingestion service. Create a Pub/Sub push subscription (in
Deployment steps below) that uses a service account. Then grant that service account the Cloud Run
Invoker role on the ingestion Cloud Run service. This ensures Pub/Sub messages can invoke the
Cloud Run endpoint. (If you choose to allow unauthenticated invocations for simplicity, you can skip
this, but restricting access is recommended.)
```
```
Cloud Scheduler Permissions: By default, Cloud Scheduler uses the App Engine default service account
to publish to Pub/Sub. Make sure that account has Pub/Sub Publisher rights on the sec-filings-
topic. This is usually YOUR_PROJECT_ID@appspot.gserviceaccount.com. You can add the
role roles/pubsub.publisher for that service account on the topic if it’s not already present.
```
### 1.

### 1.

```
13 14
```
### 1.

### 2.

```
15
3.
```
### 4.


```
Configure Environment Variables: Decide on values for environment variables needed by the
services:
```
```
BQ_TABLE_ID – This tells the Cloud Run code which BigQuery table to write to. It should be set to
your-project-id.sec_filings.sec_filings (i.e., project.dataset.table). By default
the code expects sec-filling.sec_filings.sec_filings , but you should override it with
your project/dataset.
SEC_USER_AGENT – The SEC requires a custom User-Agent string for automation. Set this to
identify your application (e.g., "MySecMonitor/1.0 (your-email@example.com)" as shown in
the code ). This is used in HTTP requests to EDGAR so that your script abides by SEC’s fair use
policy.
You will provide these env vars during Cloud Run deployment (using --set-env-vars in gcloud or
via the Cloud Run console UI).
```
With the infrastructure in place and the above configured, you’re ready to deploy the Cloud Run services
and set up the data pipeline.

## Deployment Instructions

Follow these steps to deploy the Cloud Run services and connect all the pieces of the pipeline:

```
Clone the Repository: First, clone this GitHub repository and navigate into it locally.
```
```
gitclone https://github.com/Hunterwu6/Sec_filling.git
cd Sec_filling
```
```
The key application code is in the cloud-run/ directory, which contains two subfolders for the
services:
secfillingspublisher/ – the Cloud Run service for live ingestion of filings (pulls the RSS feed).
```
```
sec-filling-backfill/ – the Cloud Run service for backfilling historical data (pulls EDGAR
index files).
```
```
Deploy the Ingestion Cloud Run Service: Use Google Cloud SDK to build and deploy the ingestion
service. You can deploy directly from source using Cloud Buildpacks. For example:
```
```
gcloud rundeploy sec-filings-ingest \
--source cloud-run/secfillingspublisher\
--region us-central1 \
--set-env-vars
BQ_TABLE_ID=YOUR_PROJECT.sec_filings.sec_filings,SEC_USER_AGENT="YourAppName/
1.0 (your-email@example.com)"\
--no-allow-unauthenticated
```
### 5.

### 6.

```
16
```
### 7.

```
17
```
### 8.

### 1.

### 2.

### 3.

### 4.


```
Replace YOUR_PROJECT with your GCP project ID, and update the region if needed. This command
will build the container from the source code and deploy it to Cloud Run as service “sec-filings-
ingest”. We disable unauthenticated access so that only authorized services (like Pub/Sub) can
invoke it.
```
_After deployment, note the Cloud Run URL for this service._ It will be of the form https://sec-filings-
ingest-<random>.run.app. You will use this in the Pub/Sub subscription in a later step.

```
Deploy the Backfill Cloud Run Service: Similarly, deploy the backfill function as another Cloud Run
service:
```
```
gcloud rundeploy sec-filings-backfill\
--source cloud-run/sec-filling-backfill\
--region us-central1 \
--set-env-vars
BQ_TABLE_ID=YOUR_PROJECT.sec_filings.sec_filings,SEC_USER_AGENT="YourAppName/
1.0 (your-email@example.com)"\
--no-allow-unauthenticated
```
```
This will deploy the historical backfill service (perhaps name it “sec-filings-backfill” ). You can also
allow this to be invokable only by authorized users. Since backfill is run on-demand (not via Pub/
Sub), you will manually trigger it when needed using an HTTP request. For example, you can use the
Cloud Run invoke command or curl with an identity token to call the URL:
```
```
https://sec-filings-backfill-<random>.run.app?year=2023&quarter=
```
```
(This would load all filings from Q4 2023 into BigQuery, for instance.) The service expects query
parameters year and quarter and will return a JSON response with counts inserted.
```
```
Create Pub/Sub Subscription for Ingestion: Now link the Pub/Sub topic to the ingestion Cloud Run
service so that messages trigger the service:
```
```
gcloud pubsubsubscriptions create sec-filings-sub\
--topic sec-filings-topic\
--push-endpoint <INGEST_CLOUD_RUN_URL>\
--push-auth-service-account <SERVICE_ACCOUNT_EMAIL>
```
```
In the above:
```
```
<INGEST_CLOUD_RUN_URL> is the URL of the sec-filings-ingest Cloud Run service (from
step 2).
<SERVICE_ACCOUNT_EMAIL> is the email of a service account that Pub/Sub will use to
authenticate when calling Cloud Run. You can use the default App Engine service account or
create a dedicated one. This service account must have the Cloud Run Invoker role on the
```
### 1.

```
18 19
```
### 2.

### ◦

### ◦


```
ingest service (granted in setup step 4). For a quick setup, you could instead allow
unauthenticated invocations on the service and omit auth here (not recommended for
production).
```
This subscription ensures that any message published to sec-filings-topic will result in an HTTP
POST to the Cloud Run ingestion endpoint. The ingestion service is designed to handle a POST by fetching
the EDGAR feed and inserting new filings , ignoring the actual message content (the Pub/Sub message
payload can be an empty JSON {} just to trigger).

```
Configure Cloud Scheduler Job: Create a Cloud Scheduler job to publish to the Pub/Sub topic on a
schedule. For example, to run every 5 minutes:
```
```
gcloud schedulerjobscreatepubsub sec-filings-schedule \
--schedule "*/5 * * * *"--timezone "UTC"\
--topic sec-filings-topic--message-body"{}"
```
```
This sets up a cron-like job that sends an empty JSON message to the sec-filings-topic every 5
minutes. When the message is published, the Pub/Sub subscription will push it to the Cloud Run
ingestion service, triggering the fetch of new filings. Adjust the frequency or time zone as needed
(default above is every 5 minutes, UTC). Ensure the scheduler’s service account has Pub/Sub publish
rights (as noted in setup).
```
```
Verify the Pipeline: After deployment, you can verify that everything is working:
```
```
Check Cloud Run logs for the ingestion service after a few intervals to see if it is fetching and
inserting filings. On a successful run, logs should show the number of filings parsed and inserted.
For example, you might see log lines like “Fetched X feed entries” and “Inserted Y rows”.
Verify in BigQuery that the sec_filings table is being populated with data. You can query the
table to see recent entries. Each new filing from EDGAR should appear as a new row in near real-
time.
Open the Looker Studio dashboard (if you have one set up) and confirm that the charts update and
reflect the incoming data (you may need to refresh or ensure the data source is set to auto-update).
If you haven’t built the dashboard yet, you can do so now by connecting BigQuery as described
below.
```
Once the pipeline is confirmed working, it will continue to ingest filings continuously. The Cloud Scheduler
→ Pub/Sub trigger ensures the ingestion Cloud Run runs at the defined interval without manual
intervention. The solution is highly scalable – even if many filings come in at once, BigQuery can handle the
insert load and Cloud Run will scale out as needed (each Pub/Sub message can spawn a new instance if the
previous run is still processing).

```
2
```
### 1.

### 2.

### 3.

```
20 21
4.
```
### 5.


## BigQuery Schema

All SEC filings ingested are stored in a BigQuery table (for example, sec_filings.sec_filings). The
schema of this table is as follows :

```
filing_date (DATE) – The filing date as reported (YYYY-MM-DD).
company_name (STRING) – Name of the company or filer.
form_type (STRING) – The SEC form type (e.g., 10-K, 8-K, 4, S-1, etc.).
cik (STRING) – The Central Index Key of the filer (unique identifier assigned by the SEC).
accession_number (STRING) – The unique accession number of the filing. This, combined with
CIK, identifies a specific filing submission.
filing_url (STRING) – URL link to the filing’s detail page or the filing document on the SEC’s
website.
```
Each entry in the table corresponds to one filing. The ingestion logic ensures no duplicate filings are stored
by checking the accession_number against existing records before inserting. The table can grow
large over time (since it will accumulate filings continuously), but BigQuery is designed to handle large
datasets with ease.

_(Note: The repository includes a sample BigQuery schema JSON file bq-sec_filings-schema.json that
defines the above fields, which can be used to create the table programmatically.)_

## Dashboard Link

The project’s Looker Studio dashboard provides a user-friendly way to explore and monitor the filings data.
Connect the BigQuery sec_filings table to Looker Studio (formerly Google Data Studio) to use it. Key
features of the dashboard include:

```
KPIs and Summary Cards: At a glance, see total number of filings ingested, number of filings in the
last day/week, or other summary statistics. These give a quick overview of activity.
Filings Over Time: A time series line chart plots the number of filings per day (or week) over time,
showing peaks on busy filing days or trends across quarters.
Filings by Form Type: A bar chart (or pie chart) breaks down filings by form type (e.g., how many 8-
Ks vs 10-Ks, etc.), highlighting which forms are most common in the selected period.
Top Companies by Filings: Another visualization can rank companies by the number of filings (using
the company_name or CIK field), identifying who has the most filings in the dataset.
Interactive Filters: Users can filter the dashboard by form type, company, or date range to focus on
particular filings of interest. For example, filter to see all 8-K filings in the last month, or all filings for
a specific company.
```
If a **public Looker Studio report link** or a **template** is available for this dashboard, it would be provided
here for one-click access. If not, you can recreate the dashboard by adding the BigQuery table as a data
source in Looker Studio and building charts as described. Ensure the data source is set to update (so new
BigQuery rows are reflected).

The dashboard is an invaluable tool for analysts or compliance teams to stay updated on SEC filings in real-
time without having to query the database directly.

```
4 5
```
### • • • • • •

```
22 23
```
### •

### •

### •

### •

### •


## Future Work

This project establishes a strong foundation for real-time SEC filings monitoring, and there are several
opportunities to extend its capabilities:

```
Industry Classification & Tagging: Enhance the dataset by mapping each company (CIK or name)
to its industry or sector. This would allow dashboard users to filter and aggregate filings by industry
(e.g., view filings only for Tech sector companies). One approach is to integrate an API or dataset that
provides industry codes for CIKs.
```
```
Real-Time Alerts: Implement an alerting system for high-priority filings. For example, set up
triggers for specific form types (such as 8-Ks, which often contain market-moving news) or specific
companies (watchlist of CIKs). When a new relevant filing is ingested, the system could send an
email, Slack message, or SMS notification to interested users.
```
```
NLP Summary of Filings: Incorporate a natural language processing step to summarize or extract
key information from filings. For instance, when a 8-K or 10-K is filed, the content could be run
through an NLP model to generate a brief summary, which could be stored in BigQuery or sent in
alerts. This would help users quickly grasp the content without reading the full filing.
```
```
Daily Email Reports: In addition to the live dashboard, the system could generate a daily email that
lists all the filings of the day (perhaps grouped by company or type), possibly with highlights for
notable filings. This could be done by scheduling a Cloud Function or Cloud Run job to query
BigQuery for the last 24 hours of data and format an email report.
```
```
API Endpoints for Data Access: Expose additional API endpoints (perhaps extend the Cloud Run
service) to allow programmatic retrieval of filings data (e.g., get all filings for a company in a date
range, etc.). This would make the system a more general platform for SEC filings data that other
applications could integrate with.
```
Each of these enhancements would make **Sec_filling** more powerful and useful for end-users. They can be
implemented incrementally on top of the current pipeline, thanks to the flexibility of the serverless
architecture.

## License and Acknowledgments

**License:** This project is licensed under the MIT License. See the LICENSE file for details (if not present, the
project owner will add one). This means you are free to use, modify, and distribute this code, provided you
include the original license notice.

**Acknowledgments:** This system was developed by Hongtao Wu as a demonstration of a fully serverless
data pipeline on GCP for monitoring SEC filings. Special thanks to the SEC’s EDGAR system for providing up-
to-date filings data (via RSS feeds and index files), and to Google Cloud’s free tier which makes it feasible to
run this pipeline at low cost. Additional thanks to any contributors or testers who provided feedback during
development.

### •

### •

### •

### •

### •


Finally, if you use or build upon this project, a shout-out or attribution is appreciated. Happy monitoring!

.bash_history
https://github.com/Hunterwu6/Sec_filling/blob/4072741644a7c12ec9d6f79018f1fda9c77f2417/.bash_history

main.py
https://github.com/Hunterwu6/Sec_filling/blob/c7a3142945acfa0c29db0424f0e5bd354848c22e/Cloud-Run/secfillingspublisher/
main.py

bq-sec_filings-schema.json
https://github.com/Hunterwu6/Sec_filling/blob/4072741644a7c12ec9d6f79018f1fda9c77f2417/bq-sec_filings-schema.json

main.py
https://github.com/Hunterwu6/Sec_filling/blob/c7a3142945acfa0c29db0424f0e5bd354848c22e/Cloud-Run/sec-filling-backfill/
main.py

```
1 15
```
```
2 3 8 9 12 16 17 20 21 22 23
```
```
4 5 13 14
```
```
6 7 10 11 18 19
```

