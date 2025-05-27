gcloud logging read  'resource.type="cloud_run_revision" AND resource.labels.service_name="ingest-fda" \
  AND severity>=ERROR'  --limit=5 --format='value(textPayload)'
help
curl -i https://ingest-cdc-133645372925.us-central1.run.app/
gcloud logging read   'resource.type="cloud_run_revision" AND resource.labels.service_name="ingest-cdc" AND severity>=ERROR'   --limit=5 --format='value(textPayload)'
gcloud logging read   'resource.type="cloud_run_revision" AND resource.labels.service_name="ingest-cdc" AND severity>=ERROR'   --limit=1 --format='value(textPayload)' | sed -n '1,120p'
gcloud logging read   'resource.type="cloud_run_revision" AND resource.labels.service_name="ingest-cdc" AND severity>=ERROR'   --limit=1   --format=json > /tmp/err.json
cat /tmp/err.json | jq -r '.[0].textPayload'
curl -X POST https://ingest-cdc-133645372925.us-central1.run.app -H "Authorization: bearer $(gcloud auth print-identity-token)" -H "Content-Type: application/json" -d '{  "name": "Developer" }'curl https://ingest-cdc-…a.run.app   # should return {"inserted": N}
curl https://ingest-cdc-133645372925.us-central1.run.app
https://ingest-cdc-133645372925.us-central1.run.app
curl -i https://ingest-cdc-133645372925.us-central1.run.app/
gcloud logging read   'resource.type="cloud_run_revision" AND resource.labels.service_name="ingest-cdc" AND severity>=ERROR'   --limit=1 --format='value(textPayload)' | tail -n 20
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="ingest-cdc" AND severity>=ERROR' --limit=1 --format="value(textPayload)" | tail -n 40
curl -i https://ingest-cdc-133645372925.us-central1.run.app/
hunterwuwork@cloudshell:~ (food-recall-alerts-458816)$ curl -i https://ingest-cdc-133645372925.us-central1.run.app/
curl -i https://ingest-cdc-133645372925.us-central1.run.app/
PROJECT_ID="food-recall-alerts-458816"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
gcloud projects add-iam-policy-binding "$PROJECT_ID"   --member="serviceAccount:${SA}"   --role="roles/datastore.user"
curl -i https://ingest-cdc-133645372925.us-central1.run.app/
{ insertId: "6okskhdhqxl"; labels: {0}; logName: "projects/food-recall-alerts-458816/logs/cloudaudit.googleapis.com%2Factivity"; payload: "protoPayload"; protoPayload: {; @type: "type.googleapis.com/google.cloud.audit.AuditLog"; authenticationInfo: {1}; authorizationInfo: [; 0: {5}; ]; methodName: "google.cloud.run.v1.Services.ReplaceService"; redactions: [; 0: {3}; ]; request: {; @type: "type.googleapis.com/google.cloud.run.v1.ReplaceServiceRequest"; name: "projects/food-recall-alerts-458816/locations/us-central1/services/ingest-fda"; region: "us-central1"; service: {5}; }
requestMetadata: {
callerIp: "2600:4040:2bc2:a00:a185:e7a6:1607:ea01"
callerSuppliedUserAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36,gzip(gfe),gzip(gfe)"
destinationAttributes: {
}
requestAttributes: {
auth: {0}
reason: "8uSywAYQGg5Db2xpc2V1bSBGbG93cw"
time: "2025-05-05T00:07:52.426894Z"
}
resourceLocation: {
currentLocations: [1]
}
resourceName: "namespaces/food-recall-alerts-458816/services/ingest-fda"
serviceName: "run.googleapis.com"
status: {
code: 3
message: "spec.template.spec.containers.resources.limits.cpu: Invalid value specified for cpu. For the specified value, maxScale may not exceed 50.
Consider running your workload in a region with greater capacity, decreasing your requested cpu-per-instance, or requesting an increase in quota for this region if you are seeing sustained usage near this limit, see https://cloud.google.com/run/quotas."
}
receiveLocation: "us-central1"
receiveTimestamp: "2025-05-05T00:07:52.927321064Z"
resource: {
labels: {
location: "us-central1"
project_id: "food-recall-alerts-458816"
service_name: "ingest-fda"
}
type: "cloud_run_revision"
}
severity: "ERROR"
timestamp: "2025-05-05T00:07:52.307807Z"
traceSampled: false
}
curl -i https://ingest-cdc-133645372925.us-central1.run.app/
curl -i https://ingest-fda-133645372925.us-central1.run.app/
gcloud logging read   'resource.type="cloud_run_revision" AND resource.labels.service_name="ingest-fda" AND severity>=ERROR'   --limit=1 --format='value(textPayload)' | tail -n 40
curl -i https://ingest-fda-133645372925.us-central1.run.app/
curl -i https://ingest-fsis- 133645372925  -uc.a.run.app/
curl -i https://ingest-fsis-133645372925.us-central1.run.app/
curl -w '\n%{http_code}\n' -s   "https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=5"   | jq '.[].field_recall_number'
curl -s "https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=5" | jq '.[].field_recall_number'
curl -s -w '\nHTTP:%{http_code}\n' -o /tmp/fsis.json      "https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=5"
cat /tmp/fsis.json | jq '.[].field_recall_number'
# 1. Quick test, JSON only
curl -s "https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=5" | jq '.[].field_recall_number'
# 2. JSON + status code
curl -s -w '\nHTTP:%{http_code}\n' -o /tmp/fsis.json      "https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=5"
cat /tmp/fsis.json | jq '.[].field_recall_number'
# A. DNS + TCP check (no TLS yet)
nc -vz www.fsis.usda.gov 443
# Expected: "succeeded!" (if you see "timed out" → network path is blocked)
# B. Verbose curl (shows TLS handshake)
curl -v --max-time 20      "https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=1"
# A. DNS + TCP check (no TLS yet)
nc -vz www.fsis.usda.gov 443
# Expected: "succeeded!" (if you see "timed out" → network path is blocked)
# B. Verbose curl (shows TLS handshake)
curl -v --max-time 20      "https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=1"
# Force HTTP/1.1  + send Accept header
curl --http1.1 -H 'Accept: application/json'      -s "https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=3" | jq '.[].field_recall_number'
# Force HTTP/1.1  + send Accept header
curl --http1.1 -H 'Accept: application/json'      -s "https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=3" | jq '.[].field_recall_number'
curl -s "http://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=3" | jq '.[].field_recall_number'
FSIS_URL = "http://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=100"
curl -s "http://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=3" | jq '.[].field_recall_number'
curl -i https://ingest-fsis-133645372925.us-central1.run.app/
curl --http1.1 -H 'Accept: application/json'      -s 'https://www.fsis.usda.gov/fsis/api/recall/v/1?max_results=3'      | jq '.[].field_recall_number'
curl -i https://ingest-fsis-133645372925.us-central1.run.app/
curl -X POST https://ingest-fsis-133645372925.us-central1.run.app -H "Authorization: bearer $(gcloud auth print-identity-token)" -H "Content-Type: application/json" -d '{  "name": "Developer" }'
curl -i https://ingest-fsis-133645372925.us-central1.run.app/
curl -i https://fsa-cpsa-ingest-133645372925.us-central1.run.app
curl -I "https://data.food.gov.uk/food-alerts/data?_limit=1"
curl -I "http://data.food.gov.uk/food-alerts/data?_limit=1"
curl -I "https://www.saferproducts.gov/RestWebServices/Recall?format=json&limit=1"
curl -I "https://data.food.gov.uk/food-alerts/data?_limit=1"
curl -I "https://www.saferproducts.gov/RestWebServices/Recall?format=json&limit=1"
curl -s "https://api.food.gov.uk/alerts?size=3" | jq '.[].title'
curl -s "https://data.food.gov.uk/food-alerts/data?_limit=3" | jq '.[].title'
curl -s "https://www.saferproducts.gov/RestWebServices/Recall?format=json&limit=3"      | jq '.[].Title'
curl -s "https://api.food.gov.uk/alerts?size=3" | jq .
curl -s "https://api.food.gov.uk/alerts?size=3" | jq
curl -s https:// fsa-cpsa-ingest-133645372925  .a.run.app | jq
curl -s https:// fsa-cpsa-ingest-133645372925.a.run.app | jq
hunterwuwork@cloudshell:~ (food-recall-alerts-458816)$ 
curl -s https://fsa-cpsa-ingest-133645372925.a.run.app | jq
curl -i https://fsa-cpsa-ingest-133645372925.us-central1.run.app
curl -s https://fetch-fsis-new-133645372925.us-central1.run.app/ | jq
curl -s https://fetch-fsis-new-133645372925.us-central1.run.app
curl -s https://fetch-fsis-new-133645372925.us-central1.run.app/ | jq
curl -s https://fetch-fsis-new-133645372925.us-central1.run.app
curl -v ${https://secfillingspublisher-504935819158.us-central1.run.app}
curl -v https://secfillingspublisher-504935819158.us-central1.run.app
curl -i https://secfillingspublisher-504935819158.us-central1.run.app
gcloud pubsub topics publish sec-filings-topic --message "{}"
curl -v https://secfillingspublisher-504935819158.us-central1.run.app
gcloud pubsub topics publish sec-filings-topic   --message '{"test":"ping"}'
$ gcloud auth login
gcloud auth login
gcloud pubsub topics publish sec-filings-topic   --message '{"test":"ping"}'
gcloud logging tail   'resource.type="cloud_run_revision" AND \
   resource.labels.service_name="secfillingspublisher"'   --format="table(timestamp, severity, textPayload)"
gcloud beta logging tail   "resource.type=cloud_run_revision AND \
   resource.labels.service_name=secfillingspublisher"   --format="table(timestamp, severity, textPayload)"
gcloud pubsub topics publish sec-filings-topic --message '{"dummy":"ping"}'
gcloud beta logging tail   "resource.type=cloud_run_revision AND resource.labels.service_name=secfillingspublisher"   --format="table(timestamp, severity, textPayload)"
gcloud pubsub topics publish sec-filings-topic --message '{"dummy":"ping"}'
gcloud pubsub topics publish sec-filings-topic --message '{"ping": true}'
gcloud pubsub topics publish sec-filings-topic --message '{"ping":true}'
gcloud pubsub topics publish sec-filings-topic --message='{"ping":true}'
gcloud pubsub topics publish sec-filings-topic --message='{"ping":true}'
gcloud pubsub topics publish sec-filings-topic --message '{"test":"ping"}'
gcloud pubsub topics publish sec-filings-topic --message='{"ping":true}'
https://secfillingspublisher-504935819158.us-central1.run.app.uc.a.run.app/debug
https://secfillingspublisher-504935819158.us-central1.run.app/debug
curl -i https://secfillingspublisher-504935819158.us-central1.run.app/debug
curl -i   -X POST   -H "Content-Type: application/json"   -d '{}'   https://secfillingspublisher-504935819158.us-central1.run.app/debug
curl -i   -X POST   -H "Ce-Specversion: 1.0"   -H "Ce-Id:    test-1234"   -H "Ce-Source: sec-filing-demo"   -H "Ce-Type:  google.cloud.pubsub.topic.v1.messagePublished"   -H "Content-Type: application/json"   -d '{
        "message": {
          "data": "",
          "attributes": {}
        }
      }' https://secfillingspublisher-504935819158.us-central1.run.app/
gcloud logging read   'resource.type="cloud_run_revision" AND
   resource.labels.service_name="secfillingspublisher"'   --limit 20   --format="value(textPayload)"
gcloud pubsub topics publish sec-filings-topic --message '{"ping":1}'
gcloud pubsub topics publish sec-filings-topic --message '{"test":1}'
gcloud pubsub topics publish sec-filings-topic --message='{"ping":true}'
curl -X POST https://REGION-PROJECT.cloudfunctions.net/FUNCTION_NAME   -H "Content-Type: application/json"   -d '{}'
gcloud pubsub topics publish sec-filings-topic --message='{"ping":true}'
curl https://secfillingspublisher-504935819158.us-central1.run.app/debug
curl -X POST https://secfillingspublisher-504935819158.us-central1.run.app/ -d '{}' -H "Content-Type: application/json"
gcloud pubsub topics publish sec-filings-topic --message='{"ping":true}'
curl -X POST https://secfillingspublisher-504935819158.us-central1.run.app/   -H "Content-Type: application/json"   -d '{}'
curl https://secfillingspublisher-504935819158.us-central1.run.app/debug
gcloud pubsub topics publish sec-filings-topic --message='{"ping":true}'
curl -X POST https://secfillingspublisher-504935819158.us-central1.run.app/run_backfill
curl "https://secfilingspublisher-504935819158.us-central1.run.app/run_backfill?initial=true"
curl -X POST https://sec-filling-backfill-504935819158.us-central1.run.app
curl -X POST https://sec-filling-backfill-504935819158.us-central1.run.app/run_backfill
bq query --use_legacy_sql=false   'TRUNCATE TABLE `sec-filling.sec_filings.sec_filings`'
curl -X POST https://sec-filling-backfill-504935819158.us-central1.run.app/run_backfill
hunterwuwork@cloudshell:~ (sec-filling)$ 
curl -X POST https://sec-filling-backfill-504935819158.us-central1.run.app/run_backfill
curl -XPOST https://sec-filling-backfill-504935819158.us-central1.run.app/run_backfill
curl -X POST https://sec-filling-backfill-504935819158.us-central1.run.app/run_backfill
for y in {1993..2025}; do   for q in 1 2 3 4; do     gcloud functions call sec_backfill_quarter       --data '{"year":"'"$y"'","quarter":"'"$q"'"}';   done; done
gcloud auth login
curl -X POST   "https://sec-filling-backfill-504935819158.us-central1.run.app/sec_backfill_quarter?year=1994&quarter=1" 
for y in {1993..2025}; do   for q in 1 2 3 4; do     gcloud functions call sec-filling-backfill       --data '{"year":"'"$y"'","quarter":"'"$q"'"}';   done; done
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1994&quarter=1"
for year in {1994..2025}; do   for quarter in 1 2 3 4; do
    if [[ $year -eq 1994 && $quarter -lt 2 ]]; then       continue;     fi
    if [[ $year -eq 2025 && $quarter -gt 1 ]]; then       continue;     fi;     curl -X POST       "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=${year}&quarter=${quarter}"       && echo " → OK ${year} Q${quarter}"       || echo " → FAIL ${year} Q${quarter}";   done; done
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1996&quarter=2"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1996&quarter=3"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1996&quarter=2"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1996&quarter=3"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1996&quarter=4"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1997&quarter=1"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1997&quarter=2"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1997&quarter=3"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=1997&quarter=4"
for year in {1998..2025}; do    for quarter in 1 2 3 4; do     fi
done
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2022&quarter=1"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2022&quarter=2"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2022&quarter=3"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2022&quarter=4"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2023&quarter=1"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2024&quarter=2"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2023&quarter=2"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2023&quarter=3"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2023&quarter=4"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2024&quarter=1"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2024&quarter=3"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2024&quarter=4"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2025&quarter=1"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2025&quarter=2"
cd ~/sec-filling 
ls
find ~ -maxdepth 3 -type f -name main.py 2>/dev/null
bq show   --format=prettyjson   sec-filling:sec_filings.sec_filings   > bq-sec_filings-schema.json
https://sec-filling-backfill-504935819158.us-central1.run.app/run_backfill?year=2024&quarter=2
https://sec-filling-backfill-504935819158.us-central1.run.app/run_quarter?year=2024&quarter=2
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2024&quarter=2"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2024&quarter=3"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2024&quarter=4"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2025&quarter=1"
curl "https://sec-filling-backfill-504935819158.us-central1.run.app/?year=2025&quarter=2"
git add
git init
git add
