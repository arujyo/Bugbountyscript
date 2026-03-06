#!/bin/bash

# Usage: bash ultimate_subdomain_recon.sh subs.txt

if [ -z "$1" ]; then
  echo "Usage: bash ultimate_subdomain_recon.sh subdomains.txt"
  exit 1
fi

input="$1"

TXT_REPORT="recon_report.txt"
CSV_REPORT="recon_report.csv"
JS_REPORT="js_files.txt"

echo "[+] Starting Ultimate Subdomain Recon"

# Reset output files
echo "Subdomain | IP | Protocol | Status | Server | CDN | Notes" > "$CSV_REPORT"
> "$TXT_REPORT"
> "$JS_REPORT"

while read -r sub; do
  [ -z "$sub" ] && continue

  echo "====================================" | tee -a "$TXT_REPORT"
  echo "Target: $sub" | tee -a "$TXT_REPORT"

  # DNS check
  ip=$(dig +short "$sub" | head -n 1)
  if [ -z "$ip" ]; then
    echo "DNS: NO RECORD" | tee -a "$TXT_REPORT"
    continue
  fi

  echo "IP: $ip" | tee -a "$TXT_REPORT"

  for proto in http https; do
    url="$proto://$sub"

    status=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 6 "$url")
    headers=$(curl -k -s -I --connect-timeout 6 "$url")

    [ "$status" = "000" ] && continue

    server=$(echo "$headers" | grep -i "^Server:" | head -n 1 | cut -d: -f2- | xargs)
    cdn=$(echo "$headers" | grep -Ei "cf-|akamai|cloudfront|fastly" | head -n 1 | cut -d: -f1)

    echo "[$proto] Status: $status" | tee -a "$TXT_REPORT"
    echo "$headers" | grep -Ei "server:|via:|x-forwarded|cf-|akamai|strict-transport|content-security|x-frame|x-xss|x-content" \
      | tee -a "$TXT_REPORT"

    echo "$sub,$ip,$proto,$status,$server,$cdn,OK" >> "$CSV_REPORT"

    # -------------------------
    # 403 BYPASS AUTOMATION
    # -------------------------
    if [ "$status" = "403" ]; then
      echo "[!] 403 detected — trying bypasses" | tee -a "$TXT_REPORT"

      bypass_headers=(
        "X-Forwarded-For: 127.0.0.1"
        "X-Original-URL: /"
        "X-Rewrite-URL: /"
      )

      for h in "${bypass_headers[@]}"; do
        bypass_code=$(curl -k -s -o /dev/null -w "%{http_code}" -H "$h" "$url")
        echo "Bypass [$h] -> $bypass_code" | tee -a "$TXT_REPORT"
      done
    fi

    # -------------------------
    # JS FILE DISCOVERY
    # -------------------------
    if [[ "$status" =~ ^2|3 ]]; then
      echo "[+] Searching for JS files" | tee -a "$TXT_REPORT"

      curl -k -s "$url" \
        | grep -Eo 'src=["'"'"'][^"'"'"']+\.js[^"'"'"']*' \
        | sed 's/src=//g' \
        | sed 's/"//g' \
        | sed "s/'//g" \
        | while read js; do
            if [[ "$js" == http* ]]; then
              echo "$sub -> $js" | tee -a "$JS_REPORT"
            else
              echo "$sub -> $url/$js" | tee -a "$JS_REPORT"
            fi
          done
    fi

  done

done < "$input"

echo ""
echo "[+] Recon complete"
echo "[+] TXT report : $TXT_REPORT"
echo "[+] CSV report : $CSV_REPORT"
echo "[+] JS files   : $JS_REPORT"
