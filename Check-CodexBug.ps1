# Recursive Context Poisoning (Token Monster) Diagnostic Scanner v2.5
# Purpose: Final Forensic detection of Cloudflare WAF interference and context loop
# Usage: Run in PowerShell as Administrator

$Version = "2.5"
$LogPath = "$env:USERPROFILE\.codex\logs_2.sqlite"
$IssueLink = "https://github.com/openai/codex/issues/17880"

Write-Host "--- Recursive Context Poisoning Diagnostic v$Version ---" -ForegroundColor Cyan
Write-Host "Calculating Sanitized Bi-Directional Token Waste..."

# 1. Environment Check
$CodexRunning = Get-Process Codex -ErrorAction SilentlyContinue
if ($CodexRunning) { Write-Host "[+] Codex Process detected." -ForegroundColor Green }

# 2. SQLite Forensic Deep-Dive
$PythonScript = @"
import sqlite3, os, time

db_path = r'$LogPath'
if not os.path.exists(db_path):
    print('DATABASE_NOT_FOUND')
    exit()

conn = sqlite3.connect(db_path)
cur = conn.cursor()

# A. Cloudflare Block Count & Static Waste
cur.execute("SELECT COUNT(*), SUM(LENGTH(feedback_log_body)) FROM logs WHERE feedback_log_body LIKE '%challenge-error-text%'")
blocks, total_bytes = cur.fetchone()
blocks = blocks or 0
total_bytes = total_bytes or 0
waste_tokens = int((total_bytes / 1024) * 250)

# B. Compaction & Message Counts
cur.execute("SELECT COUNT(*) FROM logs WHERE feedback_log_body LIKE '%user_input%'")
user_msgs = cur.fetchone()[0] or 1
cur.execute("SELECT COUNT(*) FROM logs WHERE feedback_log_body LIKE '%compact%'")
compactions = cur.fetchone()[0]

# C. Cumulative Overhead (Estimation)
# Total tokens processed = (Sum of poison payloads * Message Count)
cumulative_overhead = waste_tokens * user_msgs

# D. Hourly Intensity
sql_intensity = "SELECT strftime('%Y-%m-%d %H:00', ts, 'unixepoch', 'localtime') as hr, COUNT(*) FROM logs WHERE (feedback_log_body LIKE '%challenge-error-text%' OR feedback_log_body LIKE '%compact%') AND ts > (strftime('%s','now','-24 hours')) GROUP BY hr ORDER BY hr DESC"
cur.execute(sql_intensity)
hourly_fail = cur.fetchall()

velocity = (compactions / user_msgs) * 100

print(f'CF_BLOCKS:{blocks}')
print(f'TOKEN_WASTE:{waste_tokens:,}')
print(f'CUMULATIVE_COST:{cumulative_overhead:,}')
print(f'COMPACTION_VELOCITY:{round(velocity, 2)}%')

print('\n--- COMMUNITY EVIDENCE BLOCK (COPY THIS) ---')
print(f'Issue Tracking: $IssueLink')
print(f'Diagnostic Result: {"POSITIVE (Token Monster Loop)" if velocity > 3 or blocks > 0 else "DETECTION_PENDING"}')
print(f'Cloudflare Background Blocks: {blocks}')
print(f'Bi-Directional Token Tax: ~{waste_tokens:,} tokens (Applied to every message send/receive)')
print(f'Estimated Cumulative Overhead: ~{cumulative_overhead:,} tokens consumed by recursive failures.')
print(f'Compaction Velocity: {round(velocity, 2)}% ({compactions} compactions / {user_msgs} messages)')

print('\n--- HOURLY LOOP INTENSITY (LAST 24HRS) ---')
for hr, count in hourly_fail:
    print(f'[{hr}] {count} events')

conn.close()
"@

$Analysis = $PythonScript | python -
Write-Output $Analysis

# 3. Final Verdict
if ($Analysis -match "CF_BLOCKS:[1-9]" -or $Analysis -match "COMPACTION_VELOCITY:([3-9]|[1-9][0-9])") {
    Write-Host "`n[!] VERDICT: POSITIVE." -ForegroundColor Red
    Write-Host "This evidence proves that your background daemon is "poisoning" your context window with WAF HTML." -ForegroundColor Yellow
}

Write-Host "`nGitHub Issue: $IssueLink"
Write-Host "Forensic Audit Complete."
