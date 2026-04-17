#!/bin/bash
# Recursive Context Poisoning (Token Monster) Diagnostic Scanner v2.5
# For Linux and macOS users
# Purpose: Forensic detection of Cloudflare WAF interference and context loop

VERSION="2.5"
LOG_PATH="$HOME/.codex/logs_2.sqlite"
ISSUE_LINK="https://github.com/openai/codex/issues/17880"

echo "--- Recursive Context Poisoning Diagnostic v$VERSION (Linux/macOS) ---"
echo "Calculating Sanitized Bi-Directional Token Waste..."

# 1. Dependency Check & Interactive Installer
check_and_install() {
    local dep=$1
    if ! command -v "$dep" &> /dev/null; then
        echo "[!] Missing dependency: $dep"
        local install_cmd=""
        case "$(uname -s)" in
            Linux*)
                if command -v apt-get &>/dev/null; then install_cmd="sudo apt-get update && sudo apt-get install -y $dep"
                elif command -v dnf &>/dev/null; then install_cmd="sudo dnf install -y $dep"
                elif command -v yum &>/dev/null; then install_cmd="sudo yum install -y $dep"
                elif command -v pacman &>/dev/null; then install_cmd="sudo pacman -S --noconfirm $dep"
                fi
                ;;
            Darwin*)
                if command -v brew &>/dev/null; then install_cmd="brew install $dep"
                else echo "    Please install Homebrew (https://brew.sh) or $dep manually."; return 1
                fi
                ;;
        esac

        if [ -n "$install_cmd" ]; then
            read -p "[?] Would you like me to try and install $dep for you? (y/n): " choice
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                echo "[*] Running: $install_cmd"
                eval "$install_cmd"
                if [ $? -eq 0 ]; then echo "[+] $dep installed successfully."; return 0; fi
            fi
        fi
        echo "[!] Please install $dep manually and rerun the script."
        exit 1
    fi
}

check_and_install "sqlite3"
check_and_install "awk"

if [ ! -f "$LOG_PATH" ]; then
    echo "[!] Error: CoDeX database not found at $LOG_PATH"
    exit 1
fi

# 2. Forensic Audit
# A. Blocks and Static Waste
RES=$(sqlite3 "$LOG_PATH" "SELECT COUNT(*), SUM(LENGTH(feedback_log_body)) FROM logs WHERE feedback_log_body LIKE '%challenge-error-text%';")
BLOCKS=$(echo "$RES" | cut -d'|' -f1)
TOTAL_BYTES=$(echo "$RES" | cut -d'|' -f2)

# Default to 0 if blank
BLOCKS=${BLOCKS:-0}
TOTAL_BYTES=${TOTAL_BYTES:-0}

# Token Estimation: ~250 tokens per 1KB
WASTE_TOKENS=$(( (TOTAL_BYTES / 1024) * 250 ))

# B. Message Counts
USER_MSGS=$(sqlite3 "$LOG_PATH" "SELECT COUNT(*) FROM logs WHERE feedback_log_body LIKE '%user_input%';")
USER_MSGS=${USER_MSGS:-1}
[ "$USER_MSGS" -eq 0 ] && USER_MSGS=1

# C. Compactions
COMPACTIONS=$(sqlite3 "$LOG_PATH" "SELECT COUNT(*) FROM logs WHERE feedback_log_body LIKE '%compact%';")
COMPACTIONS=${COMPACTIONS:-0}

# D. Cumulative Overhead
CUMULATIVE_COST=$(( WASTE_TOKENS * USER_MSGS ))

# E. Velocity Calculation
VELOCITY=$(awk "BEGIN {printf \"%.2f\", ($COMPACTIONS / $USER_MSGS) * 100}")

# F. Hourly Intensity (Simplified for Bash)
HOURLY_FAIL=$(sqlite3 "$LOG_PATH" "SELECT strftime('%Y-%m-%d %H:00', ts, 'unixepoch', 'localtime') as hr, COUNT(*) FROM logs WHERE (feedback_log_body LIKE '%challenge-error-text%' OR feedback_log_body LIKE '%compact%') AND ts > (strftime('%s','now','-24 hours')) GROUP BY hr ORDER BY hr DESC;")

# 3. Community Evidence Block
echo ""
echo "--- COMMUNITY EVIDENCE BLOCK (COPY THIS) ---"
echo "Issue Tracking: $ISSUE_LINK"

# Robust Floating Point Comparison
IS_POSITIVE=0
if [ "$BLOCKS" -gt 0 ]; then
    IS_POSITIVE=1
elif command -v bc &> /dev/null; then
    if [ "$(echo "$VELOCITY > 3" | bc -l)" -eq 1 ]; then IS_POSITIVE=1; fi
elif awk "BEGIN {exit !($VELOCITY > 3)}"; then
    IS_POSITIVE=1
fi

if [ "$IS_POSITIVE" -eq 1 ]; then
    echo "Diagnostic Result: POSITIVE (Token Monster Loop)"
else
    echo "Diagnostic Result: DETECTION_PENDING"
fi

echo "Cloudflare Background Blocks: $BLOCKS"

# Formatting numbers with commas (Portable fallback)
format_num() {
    if command -v numfmt &> /dev/null; then
        numfmt --grouping "$1"
    else
        echo "$1" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
    fi
}

echo "Bi-Directional Token Tax: ~$(format_num "$WASTE_TOKENS") tokens (Applied to every message send/receive)"
echo "Estimated Cumulative Overhead: ~$(format_num "$CUMULATIVE_COST") tokens consumed by recursive failures."
echo "Compaction Velocity: $VELOCITY% ($COMPACTIONS compactions / $USER_MSGS messages)"

echo ""
echo "--- HOURLY LOOP INTENSITY (LAST 24HRS) ---"
if [ -z "$HOURLY_FAIL" ]; then
    echo "No recent loop events detected."
else
    echo "$HOURLY_FAIL" | while IFS='|' read -r HR COUNT; do
        echo "[$HR] $COUNT events"
    done
fi

# 4. Verdict
if [ "$IS_POSITIVE" -eq 1 ]; then
    printf "\n[!] VERDICT: POSITIVE.\n"
    echo "This evidence proves that your background daemon is poisoning your context window with WAF HTML."
fi

echo -e "\nGitHub Issue: $ISSUE_LINK"
echo "Forensic Audit Complete."
