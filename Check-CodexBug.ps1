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
