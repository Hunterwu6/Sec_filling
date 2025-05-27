for y in {1993..2025}; do   for q in 1 2 3 4; do     gcloud functions call sec_backfill_quarter       --data '{"year":"'"$y"'","quarter":"'"$q"'"}';   done; done
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

