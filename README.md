# Bugbountyscript
START
  │
  ▼
[Target Identification]
  │
  ├─ Tools: subfinder, amass, assetfinder
  ▼
[Subdomain Enumeration]
  │
  ├─ Output: subs.txt
  ▼
[Live Host Detection]
  │
  ├─ Tools: httpx, httprobe
  ├─ Output: live_hosts.txt
  ▼
[Historical & JS URL Collection]
  │
  ├─ Tools: waybackurls, gau
  ├─ Output: urls.txt
  ▼
[Parameter Mining]
  │
  ├─ Tools: Arjun, ParamSpider, unfurl
  ├─ Output: param_names.txt
  ▼
[JS & API Recon]
  │
  ├─ Extract JS files → Analyze for hidden endpoints
  ├─ Detect API endpoints (REST, GraphQL)
  └─ Tools: httpx, curl, xargs
  ▼
[Vulnerability Scanning]
  │
  ├─ Tools: nuclei, gf patterns
  ├─ Targets: XSS, SQLi, LFI, SSRF, IDOR
  ▼
[XSS Discovery]
  │
  ├─ Reflected XSS
  │   └─ Tools: qsreplace, httpx
  ├─ DOM XSS
  │   └─ Tools: curl, grep, JS analysis
  └─ Stored XSS
      └─ Tools: manual marker submission, reflection checks
  ▼
[Subdomain Takeover Detection]
  │
  ├─ Tools: subjack, nuclei takeover templates
  └─ Output: takeover_targets.txt
  ▼
[Enterprise Mapping & SaaS Dependency]
  │
  ├─ Identify CNAMEs, Cloud assets, third-party SaaS (Heroku, Netlify, GitHub Pages, AWS, Azure)
  └─ Output: saas_targets.txt
  ▼
[High-Severity Analysis & Exploitation]
  │
  ├─ Prioritize: Auth bypass, IDOR, business logic flaws, payment flaws
  ├─ Tools: curl, httpx, manual logic testing
  ▼
[Reporting & Documentation]
  │
  ├─ Prepare PoC, reproduction steps, remediation
  ├─ High-quality reports → private invites & bonuses
  ▼
END

Subfinder
subfinder -d target.com -silent -all -recursive -o subfinder_subs.txt                          

Amass (Passive Mode)
amass enum -passive -d target.com -o amass_passive_subs.txt                          

CRT.sh Query
curl -s "https://crt.sh/?q=%25.target.com&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | anew crtsh_subs.txt                          

Github Dorking
github-subdomains -d target.com -t token -o github_subs.txt                          

Results Combination

cat *_subs.txt | sort -u | anew all_subs.txt

after then use aquaton tools and after then 

use aquatone_urls.txt file httprobe to find actual or mc 200 in httpx-toolkit tool to find actual live doamins 

start after  all actiual_live.txt with 200 code and go on deeper l

MANUAL TESTING START USES ACTIUAL_LIVE.TXT FIRST DOAMIN FOR TESTING 




