#!/bin/bash

# ==================================================
# BUG BOUNTY RECON FRAMEWORK – ELITE MODE v6
# Real-time wc -l after EACH command
# ==================================================

clear
cat << "EOF"

██████╗ ██╗   ██╗ ██████╗     ██████╗  ██████╗ ██╗   ██╗███╗   ██╗████████╗██╗   ██╗
██╔══██╗██║   ██║██╔════╝     ██╔══██╗██╔═══██╗██║   ██║████╗  ██║╚══██╔══╝╚██╗ ██╔╝
██████╔╝██║   ██║██║  ███╗    ██████╔╝██║   ██║██║   ██║██╔██╗ ██║   ██║    ╚████╔╝
██╔══██╗██║   ██║██║   ██║    ██╔══██╗██║   ██║██║   ██║██║╚██╗██║   ██║     ╚██╔╝
██████╔╝╚██████╔╝╚██████╔╝    ██████╔╝╚██████╔╝╚██████╔╝██║ ╚████║   ██║      ██║
╚═════╝  ╚═════╝  ╚═════╝     ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝      ╚═╝

        BUG BOUNTY RECON – ELITE MODE
        REAL‑TIME STATUS | REAL‑TIME COUNTS

EOF

# =============================
# CONFIG
# =============================
BASE="ELITE_RECON"
THREADS=3

GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; NC="\e[0m"

run()   { echo -e "${YELLOW}[ RUNNING ]${NC} $1"; }
donec() { echo -e "${GREEN}[   DONE  ]${NC} $1 → $2 lines"; }
fail()  { echo -e "${RED}[  FAILED ]${NC} $1"; }

# =============================
# ARGUMENTS
# =============================
while getopts "l:u:" opt; do
  case $opt in
    l) INPUT_FILE="$OPTARG" ;;
    u) SINGLE_TARGET="$OPTARG" ;;
  esac
done

[[ -n "$INPUT_FILE" && -n "$SINGLE_TARGET" ]] && { echo "[!] Use -l OR -u"; exit 1; }
[[ -z "$INPUT_FILE" && -z "$SINGLE_TARGET" ]] && {
  echo "Usage:"
  echo "  $0 -l domains.txt"
  echo "  $0 -u example.com"
  exit 1
}

mkdir -p "$BASE"

if [[ -n "$SINGLE_TARGET" ]]; then
  TARGETS=("$SINGLE_TARGET")
else
  mapfile -t TARGETS < "$INPUT_FILE"
fi

TOTAL=${#TARGETS[@]}
COUNT=0

# =============================
# RECON FUNCTION
# =============================
recon() {
  domain="$1"
  OUT="$BASE/$domain"
  mkdir -p "$OUT"

  run "Amass"
  amass enum -passive -d "$domain" -o "$OUT/amass.txt" >/dev/null 2>&1
  [[ -s "$OUT/amass.txt" ]] && donec "Amass" "$(wc -l < "$OUT/amass.txt")" || fail "Amass"

  run "Subfinder"
  subfinder -d "$domain" -silent -o "$OUT/subfinder.txt" >/dev/null 2>&1
  [[ -s "$OUT/subfinder.txt" ]] && donec "Subfinder" "$(wc -l < "$OUT/subfinder.txt")" || fail "Subfinder"

  run "Assetfinder"
  assetfinder --subs-only "$domain" > "$OUT/assetfinder.txt" 2>/dev/null
  [[ -s "$OUT/assetfinder.txt" ]] && donec "Assetfinder" "$(wc -l < "$OUT/assetfinder.txt")" || fail "Assetfinder"

  run "crt.sh"
  curl -s "https://crt.sh/?q=%25.$domain&output=json" |
    jq -r '.[].name_value' | sed 's/\*\.//g' > "$OUT/crtsh.txt"
  [[ -s "$OUT/crtsh.txt" ]] && donec "crt.sh" "$(wc -l < "$OUT/crtsh.txt")" || fail "crt.sh"

  run "Merge Subdomains"
  cat "$OUT/"*.txt | sort -u > "$OUT/all_subdomains.txt"
  donec "All Subdomains" "$(wc -l < "$OUT/all_subdomains.txt")"

  run "httpx"
  httpx -silent -l "$OUT/all_subdomains.txt" -o "$OUT/live.txt" >/dev/null 2>&1
  [[ -s "$OUT/live.txt" ]] && donec "Live Hosts" "$(wc -l < "$OUT/live.txt")" || fail "httpx"

  run "Aquatone"
  cat "$OUT/live.txt" | aquatone -silent -out "$OUT" >/dev/null 2>&1
  jq -r '.pages[].url' "$OUT/aquatone_session.json" 2>/dev/null |
    sort -u > "$OUT/aquatone_urls.txt"
  [[ -s "$OUT/aquatone_urls.txt" ]] && donec "Aquatone URLs" "$(wc -l < "$OUT/aquatone_urls.txt")" || fail "Aquatone"

  run "WaybackURLs"
  cat "$OUT/aquatone_urls.txt" | waybackurls | sort -u > "$OUT/wayback.txt"
  [[ -s "$OUT/wayback.txt" ]] && donec "Wayback URLs" "$(wc -l < "$OUT/wayback.txt")" || fail "WaybackURLs"

  run "JS Extraction"
  grep -i "\.js$" "$OUT/wayback.txt" | sort -u > "$OUT/js_files.txt"
  [[ -s "$OUT/js_files.txt" ]] && donec "JS Files" "$(wc -l < "$OUT/js_files.txt")" || fail "JS Files"
}

# =============================
# PARALLEL EXECUTION
# =============================
echo "[*] Targets: $TOTAL | Threads: $THREADS"
echo

for domain in "${TARGETS[@]}"; do
  ((COUNT++))
  echo -e "\n[ ${COUNT}/${TOTAL} ] 🎯 $domain"
  recon "$domain" &

  [[ $(jobs -r | wc -l) -ge $THREADS ]] && wait -n
done

wait

echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[✔] ELITE RECON COMPLETED"
echo "[✔] Output → $BASE"
echo "[✔] Real‑Time wc → ENABLED"
echo "[✔] Happy Hunting 👑"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
