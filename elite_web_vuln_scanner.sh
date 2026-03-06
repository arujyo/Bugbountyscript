#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 targets.txt"
    exit 1
fi

INPUT="$1"
OUTPUT="vuln_scan_results.txt"

echo "=========================================" > $OUTPUT
echo " ELITE WEB VULNERABILITY RECON SCANNER" >> $OUTPUT
echo "=========================================" >> $OUTPUT
echo "" >> $OUTPUT

while read target
do
    echo "----------------------------------------" | tee -a $OUTPUT
    echo "[*] Testing: $target" | tee -a $OUTPUT

    # 1️⃣ Status + Redirect
    STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$target")
    FINAL=$(curl -k -s -L -o /dev/null -w "%{url_effective}" "$target")

    echo "Status Code : $STATUS" | tee -a $OUTPUT
    echo "Final URL   : $FINAL" | tee -a $OUTPUT

    if [[ "$FINAL" != "$target" ]]; then
        echo "[!] Redirect Detected → $FINAL" | tee -a $OUTPUT
    fi

    # 2️⃣ Security Headers Check
    HEADERS=$(curl -k -s -I "$target")

    echo "Security Headers:" | tee -a $OUTPUT
    echo "$HEADERS" | grep -Ei "content-security-policy|x-frame-options|strict-transport-security|x-content-type-options" | tee -a $OUTPUT

    # 3️⃣ Open Redirect Test
    TEST_REDIRECT="$target?redirect=https://google.com"
    REDIR_RESULT=$(curl -k -s -L -o /dev/null -w "%{url_effective}" "$TEST_REDIRECT")

    if [[ "$REDIR_RESULT" == *"google.com"* ]]; then
        echo "[!!!] Potential Open Redirect Detected" | tee -a $OUTPUT
    fi

    # 4️⃣ Parameter Pollution
    POLLUTION_TEST="$target?page=1&page=999"
    POLLUTION_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" "$POLLUTION_TEST")

    echo "Pollution Test Status: $POLLUTION_STATUS" | tee -a $OUTPUT

    # 5️⃣ Basic Injection Error Check
    INJECTION_TEST="$target?page=1'"
    INJECTION_RESPONSE=$(curl -k -s "$INJECTION_TEST")

    if echo "$INJECTION_RESPONSE" | grep -qi "sql\|syntax\|mysql\|warning"; then
        echo "[!!!] Possible SQL Error Message Detected" | tee -a $OUTPUT
    fi

    # 6️⃣ XSS Reflection Check
    XSS_TEST="$target?test=<script>alert(1)</script>"
    XSS_RESPONSE=$(curl -k -s "$XSS_TEST")

    if echo "$XSS_RESPONSE" | grep -q "<script>alert(1)</script>"; then
        echo "[!!!] Possible Reflected XSS" | tee -a $OUTPUT
    fi

    # 7️⃣ LFI Pattern Check
    LFI_TEST="$target?page=../../../../etc/passwd"
    LFI_RESPONSE=$(curl -k -s "$LFI_TEST")

    if echo "$LFI_RESPONSE" | grep -q "root:x:"; then
        echo "[!!!] Possible LFI Vulnerability" | tee -a $OUTPUT
    fi

    # 8️⃣ Cache Headers
    echo "Cache Headers:" | tee -a $OUTPUT
    echo "$HEADERS" | grep -Ei "x-cache|age|via|server" | tee -a $OUTPUT

    echo "" | tee -a $OUTPUT

done < $INPUT

echo "Scan Completed. Results saved in $OUTPUT"
