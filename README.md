<div align="center">
  <img src="assets/token_monster.png" alt="CoDeX Token Monster" width="400">
  <h1>CoDeX Token Monster Diagnostic</h1>
  <p><strong>A standalone, read-only diagnostic tool for identifying Cloudflare-related session blocks and history loss in OpenAI CoDeX.</strong></p>
</div>

---

## 👹 The Problem: The "Token Monster" Loop
Certain users on the ChatGPT Plus plan may experience a persistent loop where Cloudflare session clearance expires. Instead of prompting for re-authentication, the CoDeX app's background processes (compaction and sync) capture Cloudflare's CAPTCHA HTML and attempt to process it as valid data.

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
This is an unofficial community tool. If you encounter issues with the diagnostic scanner, please open an Issue. For official CoDeX support regarding the Cloudflare bug, please refer to:
- **Official GitHub Issue**: [#17880](https://github.com/openai/codex/issues/17880)

---

## 📜 License
[MIT](LICENSE)
