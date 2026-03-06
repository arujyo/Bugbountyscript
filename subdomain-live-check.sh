#!/bin/bash

# Usage: bash subdomain_live_check.sh subs.txt

if [ -z "$1" ]; then
  echo "Usage: bash subdomain_live_check.sh subdomains.txt"
  exit 1
fi

input="$1"
output="live_subdomains.txt"

echo "[+] Starting subdomain live check..."
echo "[+] Input file: $input"
echo "[+] Output file: $output"
echo "" > "$output"

while read -r sub; do
  [ -z "$sub" ] && continue

  echo "[*] Testing: $sub"

  # DNS check
  ip=$(dig +short "$sub" | head -n 1)
  if [ -z "$ip" ]; then
    echo "    └─ DNS: NO RECORD"
    continue
  fi

  # HTTP / HTTPS check
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$sub")
  https_code=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://$sub")

  if [[ "$http_code" != "000" || "$https_code" != "000" ]]; then
    echo "    └─ LIVE | IP:$ip | HTTP:$http_code | HTTPS:$https_code"
    echo "$sub | IP:$ip | HTTP:$http_code | HTTPS:$https_code" >> "$output"
  else
    echo "    └─ BLOCKED / NO SERVICE"
  fi

done < "$input"

echo ""
echo "[+] Done!"
echo "[+] Live subdomains saved in: $output"
