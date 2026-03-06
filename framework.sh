#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 domains.txt"
  exit 1
fi

INPUT=$1
BASE="bugbounty"
SUB="$BASE/subdomains"
LIVE="$BASE/live"
B403="$BASE/403"
JS="$BASE/js"
NUC="$BASE/nuclei"
SHOT="$BASE/screenshots"
REP="$BASE/reports"

mkdir -p $SUB $LIVE $B403 $JS/{urls,files,endpoints} $NUC $SHOT $REP

echo "[+] SUBDOMAIN ENUMERATION"

subfinder -dL $INPUT -silent > $SUB/subfinder.txt

cat $INPUT | while read d; do assetfinder --subs-only $d; done > $SUB/assetfinder.txt

cat $INPUT | while read d; do
  curl -s "https://crt.sh/?q=%25.$d&output=json" | jq -r '.[].name_value'
done | sed 's/\*\.//g' > $SUB/crtsh.txt

cat $INPUT | while read d; do
  amass enum -passive -d $d -norecursive -noalts
done > $SUB/amass.txt

cat $SUB/*.txt | sort -u > $SUB/all_subdomains.txt

echo "[+] HTTPX SCAN"

httpx-toolkit -l $SUB/all_subdomains.txt \
  -status-code -ip -location -title \
  -content-length -content-type \
  -tech-detect -json -silent \
  > $LIVE/httpx.json

jq -r '.url' $LIVE/httpx.json > $LIVE/live.txt

echo "[+] 403 BYPASS"

cat $LIVE/live.txt | while read url; do
  for p in admin login dashboard; do
    curl -ks -H "X-Forwarded-For: 127.0.0.1" "$url/$p" >> $B403/results.txt
    curl -ks -X POST "$url/$p" >> $B403/results.txt
  done
done

echo "[+] JS DISCOVERY"

cat $LIVE/live.txt | while read url; do
  curl -ks "$url" | grep -oP '(?<=src=")[^"]+\.js' >> $JS/urls/js_urls.txt
done

sort -u $JS/urls/js_urls.txt > $JS/urls/unique_js.txt

cat $JS/urls/unique_js.txt | while read js; do
  fname=$(basename $js)
  curl -ks "$js" -o "$JS/files/$fname"
done

grep -RhoP '(https?:\/\/[^"]+|\/api\/[^"]+)' $JS/files > $JS/endpoints/endpoints.txt

echo "[+] NUCLEI SCAN"

nuclei -l $LIVE/live.txt \
  -severity low,medium,high,critical \
  -json -o $NUC/nuclei.json

echo "[+] SCREENSHOTS"

gowitness file -f $LIVE/live.txt -P $SHOT

echo "[+] REPORT GENERATION"

jq -r '[.url,.status_code,.ip,.location.country,.content_length,.content_type,(.tech|join(","))] | @csv' \
  $LIVE/httpx.json > $REP/httpx.csv

cat <<EOF > $REP/report.html
<html><body><h1>Bug Bounty Report</h1><pre>
$(cat $REP/httpx.csv)
</pre></body></html>
EOF

echo "[✓] FULL BUG BOUNTY FRAMEWORK COMPLETED"
