# CodeXMonster: Token Monster Diagnostic Suite (v2.2)

![CodeXMonster Logo](assets/token_monster_cf.png)

### **The Problem: Recursive Context Poisoning**
CodeXMonster is a forensic diagnostic suite designed to isolate and prove the "Token Monster" bug in OpenAI Codex. This issue occurs when a **Networking Fingerprint Mismatch** triggers a Cloudflare WAF block on background workers, causing the application to absorb 403 HTML as context. This lead to a recursive failure loop that consumes millions of tokens and results in catastrophic chat history loss.

---

## **Diagnostics v2.2: Advanced Forensic Audit**
The core tool in this suite is `Check-CodexBug.ps1`. Unlike simple log viewers, this scanner performs a deep SQLite audit to calculate the "Price of the Loop."

### **Example Diagnostic Output:**
```text
--- CodeXMonster Diagnostic v2.2 ---
Calculating Sanitized Bi-Directional Token Waste...
[+] Codex Process detected.

--- COMMUNITY EVIDENCE BLOCK ---
Issue Tracking: https://github.com/openai/codex/issues/17880
Diagnostic Result: POSITIVE (Token Monster Loop)
Cloudflare Background Blocks: 13
Bi-Directional Token Tax: ~34,025 tokens (Applied to every message send/receive)
Estimated Cumulative Overhead: ~45,117,150 tokens consumed by recursive failures.
Compaction Velocity: 0.9% (12 compactions / 1326 messages)

--- HOURLY LOOP INTENSITY (LAST 24HRS) ---
[2026-04-16 23:00] 1 events
[2026-04-16 21:00] 2 events
[2026-04-16 18:00] 4 events
[2026-04-16 14:00] 6 events
[2026-04-16 10:00] 12 events

[!] VERDICT: POSITIVE.
This evidence proves that your background daemon is poisoning your context window with WAF HTML.
```

### **Understanding the Metrics:**
*   **Bi-Directional Token Tax**: This is the static token count of the Cloudflare HTML currently stored in your logs. It is added to **every single message** you send and receive.
*   **Estimated Cumulative Overhead**: This is the "Ghost in the Machine." Because context is recursive, a 34k "Tax" multiplied by 1,300 messages creates **45 Million tokens** of wasted compute.
*   **Compaction Velocity**: Healthy apps compact context ~1% of the time. If your velocity is high, the "Monster" is eating your history.

---

## **How to Run**
1. Open **PowerShell** as **Administrator**.
2. Run the following:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
& "./Check-CodexBug.ps1"
```

## **Contributing Your Evidence**
If you receive a **POSITIVE** verdict, copy your **COMMUNITY EVIDENCE BLOCK** and post it to [OpenAI GitHub Issue #17880](https://github.com/openai/codex/issues/17880) to help the engineering team finalize a fix for the background networking stack.

---
**License**: MIT
**Author**: AzurePi
**Disclaimer**: This tool is read-only and performs no modifications to your Codex installation or data.
