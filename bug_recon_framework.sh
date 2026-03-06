#!/bin/bash

####################################
# ELITE ALL-IN-ONE BUG BOUNTY SCRIPT
####################################

if [ -z "$1" ]; then
  echo "Usage: $0 domains.txt"
  exit 1
fi

DOMAINS=$1
BASE="elite-bugbounty"
CACHE="$BASE/cache"
RECON="$BASE/recon"
LIVE="$BASE/live"
B403="$BASE/bypass403"
JS="$BASE/js"
PARAM="$BASE/params"
NUC="$BASE/nuclei"
SHOT="$BASE/screenshots"
REP="$BASE/reports"

mkdir -p $CACHE $RECON $LIVE $B403 $JS $PARAM $NUC $SHOT $REP

echo "[+] STEP 1: SUBDOMAIN ENUMERATION"

subfinder -dL $DOMAINS -silent > $RECON/subfinder.txt

cat $DOMAINS | while read d; do
  assetfinder --subs-only $d
done > $RECON/assetfinder.txt

cat $DOMAINS | while read d; do
  curl -s "https://crt.sh/?q=%25.$d&output=json" | jq -r '.[].name_value'
done | sed 's/\*\.//g' > $RECON/crtsh.txt

cat $DOMAINS | while read d; do
  amass enum -passive -d $d -norecursive -noalts
done > $RECON/amass.txt

cat $RECON/*.txt | sort -u > $RECON/all_subdomains.txt

echo "[+] STEP 2: HTTPX VALIDATION + FINGERPRINTING"

httpx-toolkit -l $RECON/all_subdomains.txt \
  -status-code -ip -location -title \
  -content-length -content-type \
  -tech-detect -cdn -asn \
  -json -silent > $LIVE/httpx.json

jq -r '.url' $LIVE/httpx.json > $LIVE/live.txt

echo "[+] STEP 3: 403 BYPASS AUTOMATION"

cat $LIVE/live.txt | while read url; do
  for path in admin login dashboard api; do
    echo "$url/$path" >> $B403/targets.txt
  done
done

ffuf -u FUZZ \
  -w $B403/targets.txt \
  -H "X-Forwarded-For: 127.0.0.1" \
  -mc 200,301,302,403 \
  -of csv -o $B403/results.csv

echo "[+] STEP 4: JAVASCRIPT DISCOVERY"

cat $LIVE/live.txt | while read url; do
  curl -ks $url | grep -oP '(?<=src=")[^"]+\.js' 
done | sort -u > $JS/js_urls.txt

cat $JS/js_urls.txt | while read js; do
  name=$(echo $js | md5sum | cut -d' ' -f1)
  curl -ks "$js" -o "$JS/$name.js"
done

grep -RhoP '(https?:\/\/[^"]+|\/api\/[^"]+)' $JS > $JS/endpoints.txt

echo "[+] STEP 5: PARAMETER MINING"

grep '?' $JS/endpoints.txt | cut -d? -f2 | tr '&' '\n' | cut -d= -f1 | sort -u > $PARAM/params.txt

echo "[+] STEP 6: NUCLEI AUTO SCAN (SMART MODE)"

nuclei -l $LIVE/live.txt \
  -severity medium,high,critical \
  -rate-limit 10 \
  -json -o $NUC/nuclei.json

echo "[+] STEP 7: SCREENSHOTS"

gowitness file -f $LIVE/live.txt -P $SHOT

echo "[+] STEP 8: REPORT GENERATION"

jq -r '[.url,.status_code,.ip,.location.country,.content_length,.content_type,(.tech|join(","))] | @csv' \
  $LIVE/httpx.json > $REP/httpx.csv

cat <<EOF > $REP/report.html
<html>
<head><title>Bug Bounty Report</title></head>
<body>
<h1>Elite Bug Bounty Recon Report</h1>
<pre>
$(cat $REP/httpx.csv)
</pre>
</body>
</html>
EOF

echo "[✓] ELITE ALL-IN-ONE BUG BOUNTY SCAN COMPLETED"
