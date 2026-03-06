#!/bin/bash

# =========================================================
# JSAnalysis - JavaScript Recon & Endpoint Extractor
#
# Author: Recon Automation
#
# NOTE:
# Prefer scanning a SINGLE domain using -u for easier
# analysis and cleaner results.
# =========================================================

start_time=$(date +%s)

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

clear

echo -e "${CYAN}"
echo "      ██╗ ███████╗ █████╗ ███╗   ██╗ █████╗ ██╗     ██╗   ██╗"
echo "      ██║ ██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     ╚██╗ ██╔╝"
echo "      ██║ ███████╗███████║██╔██╗ ██║███████║██║      ╚████╔╝ "
echo " ██   ██║ ╚════██║██╔══██║██║╚██╗██║██╔══██║██║       ╚██╔╝  "
echo " ╚█████╔╝ ███████║██║  ██║██║ ╚████║██║  ██║███████╗   ██║   "
echo "  ╚════╝  ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝   ╚═╝   "
echo ""
echo "          JavaScript Recon & Endpoint Extractor"
echo -e "${NC}"

# Tool check
for tool in gau katana waybackurls wget grep sort; do
if ! command -v $tool &> /dev/null
then
    echo -e "${RED}[-] $tool not installed${NC}"
    exit
fi
done

usage() {
echo ""
echo "Usage:"
echo "./js_analysis.sh -u example.com"
echo "./js_analysis.sh -l domains.txt"
exit 1
}

analyze_domain(){

domain=$1

echo -e "${GREEN}[+] Target: $domain${NC}"

mkdir -p JSAnalysis/$domain
cd JSAnalysis/$domain || exit

mkdir -p jsfiles

echo -e "${CYAN}[1] Collecting JS URLs (gau)${NC}"
gau $domain | grep "\.js$" | sort -u > gau_js.txt

echo -e "${CYAN}[2] Crawling JS (katana)${NC}"
katana -u https://$domain -d 3 -jc -silent -o katana_output.txt
grep "\.js$" katana_output.txt | sort -u > katana_js.txt

echo -e "${CYAN}[3] Fetching Wayback JS${NC}"
waybackurls $domain | grep "\.js$" | sort -u > wayback_js.txt

echo -e "${CYAN}[4] Combining JS URLs${NC}"
cat *_js.txt | sort -u > js_urls.txt

echo -e "${CYAN}[5] Downloading JS Files${NC}"
cat js_urls.txt | xargs -P 20 -I {} wget -q {} -P jsfiles/

echo -e "${CYAN}[6] Extracting Endpoints${NC}"
grep -rhoP "(https?:\/\/[^\"]+|\/[a-zA-Z0-9_\/\-?=&]+)" jsfiles/ \
| sort -u > endpoints.txt

echo -e "${CYAN}[7] Cleaning Endpoints${NC}"
grep -rhoP "(https?:\/\/[^\"' ]+|\/[a-zA-Z0-9_\/\-?=&\.]+)" jsfiles/ \
| grep -v "\.js" \
| sort -u > clean_endpoints.txt

echo -e "${CYAN}[8] Extracting Juicy API Endpoints${NC}"
grep -Ei "api|admin|auth|internal|v1|v2|graphql" clean_endpoints.txt > juicy.txt

echo -e "${GREEN}[✔] Analysis Complete for $domain${NC}"

cd ../../

}

while getopts "u:l:" opt; do
case ${opt} in
u )
analyze_domain $OPTARG
;;
l )
while read domain
do
analyze_domain $domain
done < $OPTARG
;;
* )
usage
;;
esac
done

if [ $OPTIND -eq 1 ]; then
usage
fi

end_time=$(date +%s)
runtime=$((end_time-start_time))

echo ""
echo -e "${YELLOW}Total Execution Time: $runtime seconds${NC}"
