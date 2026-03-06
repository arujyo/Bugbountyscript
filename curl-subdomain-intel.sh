#!/bin/bash

# Usage: bash curl_subdomain_intel.sh subs.txt

input=$1
output="curl_subdomain_report.txt"

echo "=== CURL SUBDOMAIN INTEL REPORT ===" > $output
echo "Generated on: $(date)" >> $output
echo "" >> $output

while read sub; do
  echo "########################################" >> $output
  echo "SUBDOMAIN: $sub" >> $output
  echo "########################################" >> $output

  curl -k -s -I -L \
    -w "\n--- CURL META ---\nHTTP_CODE: %{http_code}\nFINAL_URL: %{url_effective}\nTIME_TOTAL: %{time_total}\nIP: %{remote_ip}\n" \
    https://$sub \
    | egrep -i \
    "HTTP/|server:|location:|via:|x-forwarded|x-powered|x-amz|x-cache|cf-|akamai|strict-transport|content-security|x-frame|x-xss|x-content|set-cookie|content-type|referrer-policy|permissions-policy" \
    >> $output

  echo "" >> $output
done < $input

echo "[+] Done! Output saved to $output"
