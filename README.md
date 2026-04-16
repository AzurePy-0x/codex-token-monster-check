<div align="center">
  <img src="./assets/token_monster.png" alt="CoDeX Token Monster" width="400">
  <h1>CoDeX Token Monster Diagnostic</h1>
  <p><strong>A standalone, read-only diagnostic tool for identifying Cloudflare-related session blocks and history loss in OpenAI CoDeX.</strong></p>
</div>

---

## 👹 The Problem: The "Token Monster" Loop
Certain users on the ChatGPT Plus plan may experience a persistent loop where Cloudflare session clearance expires. Instead of prompting for re-authentication, the CoDeX app's background processes (compaction and sync) capture Cloudflare's CAPTCHA HTML and attempt to process it as valid data. 

This issue is tracked in the official OpenAI CoDeX repository: **[GitHub Issue #17880](https://github.com/openai/codex/issues/17880)**.

### Impact Summary
| Symptom | Severity | Description |
| :--- | :--- | :--- |
| **History Loss** | 🔴 Critical | Background compaction fails, leading to the spontaneous deletion of weeks of chat history. |
| **Phantom Tokens** | 🟠 High | Usage counters inflate exponentially (10M - 200M+) as the app loops on massive HTML payloads. |
| **Sync Blocks** | 🟡 Medium | Plugin lists, settings, and workspace configurations fail to synchronize with the cloud. |

---

## 🛠️ What This Tool Does
This PowerShell script is **strictly read-only**. it scans your local CoDeX logs and session data to find technical markers of the bug. 

- **Cloudflare Intercepts**: Identifies `challenge-error-text` within your local SQLite logs.
- **Background Sync Analysis**: Specifically flags if `startup_sync` tasks are being blocked.
- **Compaction Failure Detection**: Checks for "Error running remote compact task" markers.
- **Phantom Token Spikes**: Scans session `.jsonl` files for anomalous token growth.

---

## 🚀 Quick Start (Windows)
1. **Download**: Get `Check-CodexBug.ps1` from the [official repository](https://github.com/AzurePy-0x/CodeXMonster).
2. **Run**: Open PowerShell as a standard user and execute:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Check-CodexBug.ps1
   ```
3. **Custom Paths**: If your `.codex` folder is in a custom location:
   ```powershell
   .\Check-CodexBug.ps1 -CodexPath "D:\Custom\Path\.codex"
   ```

---

## 🛡️ Integrity & Safety
To ensure you are running the authentic, un-modified script, verify the file hash before execution:

### Official SHA-256 Checksum
`11003782188966876D2BEA1B410B34C579CF200635DEB70DAAD37836AA38E249`

### How to Verify
Run the following command in PowerShell:
```powershell
Get-FileHash -Path .\Check-CodexBug.ps1 -Algorithm SHA256
```
Compare the output to the `CHECKSUM.SHA256` file in this repository.

---

## ⚠️ Warnings & Liability

> [!WARNING]
> **Use Official Source Only**: To prevent exposure to potential malware, **never** download or run "forked" versions of this script from unverified sources. Malicious actors may modify the script to exfiltrate session data.

> [!IMPORTANT]
> **LIABILITY DISCLAIMER**: This software is provided **"AS IS"**, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement. In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

---

## 🤝 Community & Support
This is an **Open Source** tool, provided free of charge to the CoDeX community. If you encounter issues with the diagnostic scanner, please open an Issue. For official CoDeX support regarding the Cloudflare bug, please refer to:
- **Official GitHub Issue**: [#17880](https://github.com/openai/codex/issues/17880)

---

## ⚖️ License & Acknowledgements
- **License**: [MIT](LICENSE)
- **Acknowledgements**: 
  - **CoDeX** is a trademarked application developed by **OpenAI**.
  - **Cloudflare** is a registered trademark of **Cloudflare, Inc**.
  - This diagnostic tool is an unofficial community contribution and is not affiliated with, endorsed by, or sponsored by OpenAI or Cloudflare.

---

## 📄 Full Source Code (v1.3)
For transparency and easy auditing, you can view the full source code of the diagnostic script below:

<details>
<summary>Click to expand source code</summary>

```powershell
<#
.SYNOPSIS
    CoDeX - CloudFlare - Token Monster Scanner
    GitHub issue: https://github.com/openai/codex/issues/17880
    Author: Pi (https://github.com/AzurePy-0x)

.DESCRIPTION
    v1.3: Added StrictMode, enhanced error handling, and "Read-Only" assurance markers.
#>

# --- 1. Initialization & Security Policy ---
Set-StrictMode -Version Latest
$ErrorActionPreference = "SilentlyContinue"

param (
    [Parameter(Mandatory=$false)]
    [string]$CodexPath = (Join-Path $HOME ".codex")
)

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " CoDeX - CloudFlare - Token Monster Scanner " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# --- 1. Security & Path Validation ---
if (-not (Test-Path $CodexPath)) {
    Write-Host "[!] Error: Target directory not found: $CodexPath" -ForegroundColor Red
    exit
}

# Verifying CoDeX root by checking for non-sensitive markers
$markers = @("config.toml", "logs_2.sqlite", "sessions")
$isValid = $false
foreach ($marker in $markers) {
    if (Test-Path (Join-Path $CodexPath $marker)) {
        $isValid = $true
        break
    }
}

if (-not $isValid) {
    $nestedPath = Join-Path $CodexPath ".codex"
    if (Test-Path $nestedPath) { Write-Host "[!] Hint: Found a nested '.codex' folder. Point to: $nestedPath" -ForegroundColor Yellow }
    Write-Host "[!] Security Alert: Target directory does not appear to be a valid CoDeX directory." -ForegroundColor Red
    exit
}

$logsDbPath = Join-Path $CodexPath "logs_2.sqlite"
$sessionsDir = Join-Path $CodexPath "sessions"

# Helper function
function Test-FileContents {
    param([string]$Path, [string]$Pattern)
    if (-not (Test-Path $Path)) { return $false }
    return Select-String -Path $Path -Pattern $Pattern -Quiet
}

# --- 2. Diagnostic Execution ---
Write-Host "[*] Target: $CodexPath" -ForegroundColor Gray

# A. Broad Cloudflare check
$cfDetected = Test-FileContents -Path $logsDbPath -Pattern "challenge-error-text"

# B. Specific "Startup Sync" check
$syncDetected = Test-FileContents -Path $logsDbPath -Pattern "plugins::startup_sync"

# C. Specific "History Compaction" check
$compactDetected = Test-FileContents -Path $logsDbPath -Pattern "Error running remote compact task"

# D. Phantom Token check
$phantomTokens = $false
if (Test-Path $sessionsDir) {
    $spikes = Get-ChildItem -Path $sessionsDir -Filter "*.jsonl" -Recurse | 
              Select-String -Pattern '"total_tokens":([0-9]{8,})' -Quiet
    if ($spikes) { $phantomTokens = $true }
}

# --- 3. Result Reporting ---
Write-Host "`n--- Diagnostic results ---"
Write-Host "1. Cloudflare Intercepts: " -NoNewline
if($cfDetected){ Write-Host "[DETECTED]" -ForegroundColor Red } else { Write-Host "[CLEAN]" -ForegroundColor Green }

Write-Host "2. Background Sync Block: " -NoNewline
if($syncDetected){ Write-Host "[DETECTED]" -ForegroundColor Red } else { Write-Host "[CLEAN]" -ForegroundColor Green }

Write-Host "3. Compaction Failures:   " -NoNewline
if($compactDetected){ Write-Host "[DETECTED]" -ForegroundColor Red } else { Write-Host "[CLEAN]" -ForegroundColor Green }

Write-Host "4. Phantom Token Spikes:  " -NoNewline
if($phantomTokens){ Write-Host "[DETECTED]" -ForegroundColor Red } else { Write-Host "[CLEAN]" -ForegroundColor Green }


Write-Host "`n--- Analysis ---" -ForegroundColor Cyan
if ($compactDetected -or $phantomTokens) {
    Write-Host "CRITICAL: The 'Token Monster' is currently eating your chat history." -ForegroundColor Red
    Write-Host "The app is failing to summarize older messages and is likely deleting them." -ForegroundColor Yellow
}
elseif ($syncDetected) {
    Write-Host "WARNING: Background tasks are currently blocked by Cloudflare." -ForegroundColor Yellow
    Write-Host "Settings and plugins will fail to sync. History loss is imminent if a compaction triggers." -ForegroundColor Cyan
}
else {
    Write-Host "No active Token Monster markers detected. Your session appears healthy." -ForegroundColor Green
}

# --- 4. Optional Copy to Clipboard ---
Write-Host "`n------------------------------------------"
$copyPrompt = Read-Host "Would you like to copy these results to your clipboard? (y/n)"
if ($copyPrompt.ToLower() -eq 'y') {
    # Building a text-only report for clipboard
    $clipboardReport = "Cloudflare: $(if($cfDetected){'YES'}else{'NO'})`nSyncBlock: $(if($syncDetected){'YES'}else{'NO'})`nCompactFail: $(if($compactDetected){'YES'}else{'NO'})`nPhantomTokens: $(if($phantomTokens){'YES'}else{'NO'})"
    $clipboardReport | Set-Clipboard
    Write-Host "[+] Results copied to clipboard." -ForegroundColor Gray
}

Write-Host "Scanner complete. Stay safe.`n"
```
</details>
