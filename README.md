# CoDeX Token Monster Diagnostic (v1.2)

A standalone PowerShell script to detect the "Cloudflare Token Monster" bug in [OpenAI CoDeX](https://github.com/openai/codex) installations.

## The Problem
Certain users on the ChatGPT Plus plan may experience a loop where Cloudflare session clearance expires. Instead of prompting for re-auth, the CoDeX app captures Cloudflare's CAPTCHA HTML, attempts to process it as chat history, and enters a "Phantom Token" loop. 

**This leads to:**
1. **Background Sync Blocks**: Settings and plugins fail to update.
2. **Exponential Rate Usage**: Artificial usage growth (hundreds of millions of tokens).
3. **History Loss**: Spontaneous deletion of chat history from active windows.

## What This Tool Does
This script is **read-only**. It safely scans your local CoDeX logs and session data to find technical markers of the bug. It does not modify your files or upload any data.

### Diagnostic Benchmarks (v1.2):
- **Cloudflare Intercepts:** Identifies CAPTCHA HTML in your log files.
- **Background Sync Block:** Specifically identifies if plugin/startup syncing is being blocked.
- **Compaction Failures:** Detects if history-saving background tasks are failing (leads to history loss).
- **Phantom Token Spikes:** Flags token growth exceeding 10M+ tokens.

## Quick Start (Windows)
1. Download `Check-CodexBug.ps1`.
2. Open PowerShell and run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Check-CodexBug.ps1
   ```

### Custom Installations
If you use a custom `.codex` directory, provide the path as an argument:
```powershell
powershell -ExecutionPolicy Bypass -File .\Check-CodexBug.ps1 -CodexPath "D:\Custom\Path\.codex"
```

## Contributing
This is an unofficial community tool. If you find a bug in the scanner, please open an issue. For issues with CoDeX itself, please refer to the [official GitHub issue #17880](https://github.com/openai/codex/issues/17880).

## License
MIT
