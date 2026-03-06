#!/bin/bash

# ======================================================
# JS HUNTER - Advanced JavaScript Recon Framework
#
# Prefer scanning ONE domain (-u) for clean analysis
# ======================================================

start_time=$(date +%s)

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

clear

echo -e "${CYAN}"
echo "     ██╗ ███████╗    ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ "
echo "     ██║ ██╔════╝    ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗"
echo "     ██║ ███████╗    ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝"
echo "██   ██║ ╚════██║    ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗"
echo "╚█████╔╝ ███████║    ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║"
echo " ╚════╝  ╚══════╝    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
echo ""
echo "        Advanced JavaScript Recon Framework"
echo -e "${NC}"

# Tool check
for tool in gau katana waybackurls wget grep sort; do
if ! command -v $tool &> /dev/null
then
echo -e "${RED}[-] $tool not installed${NC}"
exit
fi
done

usage(){
echo ""
echo "Usage:"
echo "./js_hunter.sh -u example.com"
echo "./js_hunter.sh -l domains.txt"
exit
}

scan_domain(){

domain=$1

echo -e "${GREEN}[+] Target: $domain${NC}"

mkdir -p JSHunter/$domain
cd JSHunter/$domain || exit

mkdir -p jsfiles

echo -e "${CYAN}[1] Collecting JS URLs (gau)${NC}"
gau $domain | grep "\.js$" | sort -u > gau_js.txt

echo -e "${CYAN}[2] Crawling JS (katana)${NC}"
katana -u https://$domain -d 3 -jc -silent -o katana.txt
grep "\.js$" katana.txt | sort -u > katana_js.txt

echo -e "${CYAN}[3] Wayback JS Collection${NC}"
waybackurls $domain | grep "\.js$" | sort -u > wayback_js.txt

echo -e "${CYAN}[4] Combining JS URLs${NC}"
cat *_js.txt | sort -u > js_urls.txt

echo -e "${CYAN}[5] Downloading JS Files${NC}"
cat js_urls.txt | xargs -P 25 -I {} wget -q {} -P jsfiles/

echo -e "${CYAN}[6] Extracting Endpoints${NC}"
grep -rhoP "(https?:\/\/[^\"]+|\/[a-zA-Z0-9_\/\-?=&]+)" jsfiles/ | sort -u > endpoints.txt

echo -e "${CYAN}[7] Cleaning Endpoints${NC}"
grep -rhoP "(https?:\/\/[^\"' ]+|\/[a-zA-Z0-9_\/\-?=&\.]+)" jsfiles/ \
| grep -v "\.js" \
| sort -u > clean_endpoints.txt

echo -e "${CYAN}[8] Extracting API / Admin / Auth Endpoints${NC}"
grep -Ei "api|admin|auth|internal|v1|v2|graphql|private" clean_endpoints.txt > juicy_endpoints.txt

echo -e "${CYAN}[9] Extracting Parameters${NC}"
grep "=" clean_endpoints.txt | sort -u > parameters.txt

echo -e "${CYAN}[10] GraphQL Endpoint Detection${NC}"
grep -Ei "graphql" clean_endpoints.txt > graphql.txt

echo -e "${CYAN}[11] Searching for Secrets / API Keys${NC}"

grep -rhoEi "apikey|api_key|token|secret|client_secret|access_token|aws_access_key_id|aws_secret_access_key" jsfiles/ \
| sort -u > secrets.txt

echo -e "${CYAN}[12] Finding Cloud Keys${NC}"

grep -rhoE "AIza[0-9A-Za-z\-_]{35}" jsfiles/ > google_api_keys.txt
grep -rhoE "AKIA[0-9A-Z]{16}" jsfiles/ > aws_keys.txt

echo -e "${GREEN}[✔] JS Recon Completed for $domain${NC}"

cd ../../

}

while getopts "u:l:" opt
do
case ${opt} in
u )
scan_domain $OPTARG
;;
l )
while read domain
do
scan_domain $domain
done < $OPTARG
;;
* )
usage
;;
esac
done

if [ $OPTIND -eq 1 ]
then
usage
fi

end_time=$(date +%s)
runtime=$((end_time-start_time))

echo ""
echo -e "${YELLOW}Scan Completed in $runtime seconds${NC}"
