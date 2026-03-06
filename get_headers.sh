#!/bin/bash

# =====================================
# HTTP Header Collector
# =====================================

start_time=$(date +%s)

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

clear

echo -e "${CYAN}"
echo " _    _                _                "
echo "| |  | |              | |               "
echo "| |__| | ___  __ _  __| | ___ _ __      "
echo "|  __  |/ _ \/ _\` |/ _\` |/ _ \ '__|     "
echo "| |  | |  __/ (_| | (_| |  __/ |        "
echo "|_|  |_|\___|\__,_|\__,_|\___|_|        "
echo ""
echo "      HTTP Header Collector"
echo -e "${NC}"

# Check curl
if ! command -v curl &> /dev/null; then
    echo -e "${RED}[-] curl is not installed${NC}"
    exit
fi

# Create headers directory
mkdir -p headers

# Usage
usage() {
echo -e "${YELLOW}"
echo "Usage:"
echo "$0 -u https://example.com"
echo "$0 -l urls.txt"
echo -e "${NC}"
exit 1
}

# Function to fetch headers
get_headers() {

url=$1

# clean filename
name=$(echo "$url" | sed 's|https\?://||g' | tr '/' '_')

echo -e "${GREEN}[+] Fetching headers for: $url${NC}"

curl -s -I "$url" > "headers/$name.txt"

echo -e "${CYAN}[✔] Saved -> headers/$name.txt${NC}"
}

# Argument parsing
while getopts "u:l:" opt; do
    case ${opt} in
        u )
            get_headers "$OPTARG"
            ;;
        l )
            while read url; do
                get_headers "$url"
            done < "$OPTARG"
            ;;
        * )
            usage
            ;;
    esac
done

if [ $OPTIND -eq 1 ]; then
    usage
fi

# Execution time
end_time=$(date +%s)
runtime=$((end_time-start_time))

echo ""
echo -e "${YELLOW}Execution Time: ${runtime} seconds${NC}"
