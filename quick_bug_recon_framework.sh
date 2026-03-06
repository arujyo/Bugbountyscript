#!/bin/bash

########################################
# ELITE BUG BOUNTY FRAMEWORK (STABLE)
########################################

if [ -z "$1" ]; then
  echo "Usage: $0 domains.txt"
  exit 1
fi

DOMAINS=$1
BASE="bugbounty"
SUB="$BASE/subdomains"
LIVE="$BASE/live"
B403="$BASE/403"
JS="$BASE/js"
NUC="$BASE/nuclei"
SHOT="$BASE/screenshots"
REP="$BASE/reports"

mkdir -p "$SUB" "$LIVE" "$B403" "$JS" "$NUC" "$SHOT" "$REP"

echo "[+] STEP 1: SUBDOMAIN ENUMERATION"

echo "[+] subfinder"
subfinder -dL "$DOMAINS" -silent > "$SUB/subfinder.txt"

echo "[+] assetfinder"
while read -r d; do
  assetfinder --subs-only "$d"
done < "$DOMAINS" > "$SUB/assetfinder.txt"

echo "[+] crt.sh (SAFE MODE)"
while read -r d; do
  curl -s "https://crt.sh/?q=%25.$d&output=json" |
  jq -r 'if type=="array" then .[].name_value else empty end' 2>/dev/null |
  sed 's/\*\.//g'
done < "$DOMAINS" > "$SUB/crtsh.txt"

echo "[+] amass passive"
while read -r d; do
  amass enum -passive -d "$d" -norecursive -noalts
done < "$DOMAINS" > "$SUB/amass.txt"

cat "$SUB"/*.txt | sort -u > "$SUB/all_subdomains.txt"

echo "[✓] Subdomains collected: $(wc -l < "$SUB/all_subdomains.txt")"

---

echo "[+] STEP 2: HTTPX VALIDATION (JSON SAFE)"

httpx-toolkit -l "$SUB/all_subdomains.txt" \
  -status-code -ip -location -title \
  -content-length -content-type \
  -tech-detect -cdn -asn \
  -json -silent > "$LIVE/httpx.json"

# keep only valid JSON lines
jq -c 'select(type=="object")' "$LIVE/httpx.json" > "$LIVE/httpx_clean.json"
mv "$LIVE/httpx_clean.json" "$LIVE/httpx.json"

jq -r '.url' "$LIVE/httpx.json" > "$LIVE/live.txt"

echo "[✓] Live hosts: $(wc -l < "$LIVE/live.txt")"

---

echo "[+] STEP 3: 403 BYPASS AUTOMATION"

> "$B403/targets.txt"

while read -r url; do
  for path in admin login dashboard api; do
    echo "$url/$path" >> "$B403/targets.txt"
  done
done < "$LIVE/live.txt"

ffuf -u FUZZ \
  -w "$B403/targets.txt" \
  -H "X-Forwarded-For: 127.0.0.1" \
  -mc 200,301,302,403 \
  -of csv -o "$B403/results.csv" >/dev/null

---

echo "[+] STEP 4: JAVASCRIPT DISCOVERY"

> "$JS/js_urls.txt"

while read -r url; do
  curl -ks "$url" | grep -oP '(?<=src=")[^"]+\.js'
done < "$LIVE/live.txt" | sort -u >> "$JS/js_urls.txt"

mkdir -p "$JS/files"

while read -r js; do
  name=$(echo "$js" | md5sum | cut -d' ' -f1)
  curl -ks "$js" -o "$JS/files/$name.js"
done < "$JS/js_urls.txt"

grep -RhoP '(https?:\/\/[^"]+|\/api\/[^"]+)' "$JS/files" \
  | sort -u > "$JS/endpoints.txt"

---

echo "[+] STEP 5: PARAMETER MINING"

grep '?' "$JS/endpoints.txt" 2>/dev/null \
  | cut -d? -f2 \
  | tr '&' '\n' \
  | cut -d= -f1 \
  | sort -u > "$JS/params.txt"

---

echo "[+] STEP 6: NUCLEI AUTO SCAN (SMART)"

nuclei -l "$LIVE/live.txt" \
  -severity medium,high,critical \
  -rate-limit 10 \
  -json -o "$NUC/nuclei.json" >/dev/null

---

echo "[+] STEP 7: SCREENSHOTS"

gowitness file -f "$LIVE/live.txt" -P "$SHOT" >/dev/null

---

echo "[+] STEP 8: REPORT GENERATION (SAFE)"

jq -r '
  select(type=="object") |
  [
    .url,
    (.status_code // "N/A"),
    (.ip // "N/A"),
    (.location.country // "N/A"),
    (.content_length // "N/A"),
    (.content_type // "N/A"),
    ((.tech // []) | join(","))
  ] | @csv
' "$LIVE/httpx.json" > "$REP/httpx.csv"

cat <<EOF > "$REP/report.html"
<html>
<head><title>Bug Bounty Recon Report</title></head>
<body>
<h1>Recon Results</h1>
<pre>
$(cat "$REP/httpx.csv")
</pre>
</body>
</html>
EOF

echo "[✓] FRAMEWORK COMPLETED SUCCESSFULLY"
