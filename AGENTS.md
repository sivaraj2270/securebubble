# SecureBubble AI — Agent Rules

## Project
- Android + Flutter security application. Package: `com.sivaraj.securebubble_pro`
- Repo: `sivaraj2270/securebubble`
- Existing, working, DO NOT REWRITE: Flutter UI, Firebase auth, Dashboard,
  MainActivity, NotificationHelper, BubbleService, MethodChannel bridge,
  overlay permission flow, floating bubble.
- Current phase: dual-provider URL verification (VirusTotal + Google Web Risk)
  with an independent comparison engine, risk engine, and a separate admin portal.

## Non-negotiable security rules
1. No API key, service-account JSON, or provider credential may appear in Dart,
   Kotlin, Java, XML, Gradle, the APK, or any committed file. Backend only.
2. `.env` is gitignored. Secrets are read from environment variables at runtime.
3. A provider error, timeout, or missing response is `UNKNOWN` — never `SAFE`.
   `SAFE` and `NOT CHECKED` are distinct states everywhere in the codebase.
4. Admin authorization is verified server-side on every admin endpoint using a
   server-controlled role claim. A client-supplied `isAdmin` flag is never trusted.
5. Never fabricate provider output. If VirusTotal returned no data, the response
   field says so. No placeholder counts, no invented verdicts.
6. Never log secrets, tokens, passwords, full message bodies, or screen contents.
7. No root, no hidden/private Android APIs, no code injection into third-party
   apps, no HTTPS MITM, no CA installation, no continuous silent screen capture.
8. AccessibilityService reads only currently visible content. Never claim to
   scan chat history.
9. Domain blocking must match `example.com`, `www.example.com`,
   `login.example.com` — and must NOT match `example.com.evil.com`.
   Suffix matching must be label-boundary aware.
10. Privacy: persist domain, normalized URL, scan result, risk score, timestamp,
    provider results. Do not persist message bodies or screenshots.

## Architecture
Mobile → `POST /api/v1/scan/url` → backend → VirusTotal ∥ Google Web Risk
→ normalize → Comparison Engine → Risk Engine → single normalized result → popup.

Backend: Python, FastAPI, SQLAlchemy. Layout:
backend/{main.py,config.py,requirements.txt}, routes/{scan,admin,auth,analytics}.py,
services/{virustotal_service,google_web_risk_service,comparison_engine,risk_engine,threat_intelligence}.py,
models/{scan,threat,admin}.py, database/database.py

Comparison states: BOTH_SAFE, BOTH_DANGEROUS, BOTH_SUSPICIOUS,
VT_SAFE_GOOGLE_DANGEROUS, VT_DANGEROUS_GOOGLE_SAFE, VT_SUSPICIOUS_GOOGLE_SAFE,
VT_SAFE_GOOGLE_SUSPICIOUS, INSUFFICIENT_DATA, PROVIDER_ERROR.

Risk bands: 0–30 SAFE · 31–60 SUSPICIOUS · 61–89 HIGH RISK · 90–100 CRITICAL.
Every score must carry an explainable list of contributing signals. An LLM never
decides maliciousness — scoring is deterministic and rule-based.

## Working style
- One file per turn. Complete file contents, not diffs or fragments.
- Before editing an existing file, read it first and state what you are preserving.
- End every turn with: the file path, how to run/test it, and `Awaiting DONE.`
- Do not begin the next step until the user replies `DONE`.
- If a requirement is ambiguous, ask one question rather than guessing.
