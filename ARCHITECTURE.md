# SECUREBUBBLE AI / NUKEZERO SHIELD — Platform Architecture & Security Model

## 1. Executive Summary

**SecureBubble AI / NUKEZERO SHIELD** is a production-grade, privacy-first mobile cybersecurity platform designed around the core operational rule: **"SCAN BEFORE YOU CLICK"**. 

The platform protects Android users against phishing URLs, malicious QR codes, disguised hyperlinks, scam messages, homograph IDN attacks, and brand impersonation attempts across third-party applications.

---

## 2. Layered Threat Detection Architecture

```text
               User Encountered Content
                          ↓
              SecureBubble Floating Overlay
                          ↓
      Clean Screen Capture & Accessibility Node Inspection
                          ↓
                 Input Normalization
                          ↓
┌─────────────────────────────────────────────────────────┐
│              Modular Threat Analysis Engine             │
├─────────────────────────────────────────────────────────┤
│ • LinkDetector (URL & Scheme Extraction)               │
│ • QRManager (ML Kit + ZXing Barcode Decoder)            │
│ • OCRManager (Multi-Pass High-Contrast OCR)             │
│ • RedirectAnalyzer (HTTP Redirect Chain Tracer)         │
│ • HomographDetector (IDN & Punycode Scanner)            │
│ • BrandSimilarityEngine (Levenshtein Edit Distance)     │
│ • ScamMessageDetector (NLP Social Engineering Rules)    │
│ • FileThreatAnalyzer (Extension & Hash Inspector)       │
│ • VirusTotal API v3 Threat Intelligence Adapter        │
└─────────────────────────────────────────────────────────┘
                          ↓
        0–100 Weighted Risk Scoring Engine
                          ↓
     ┌────────────────────┬────────────────────┐
     │ 0–25: SAFE         │ 26–50: LOW RISK    │
     │ 51–75: SUSPICIOUS  │ 76–100: DANGEROUS  │
     └────────────────────┴────────────────────┘
                          ↓
        Compact Native Popup Overlay & Alert Dialog
```

---

## 3. Core Component Breakdown

### 📱 Android Application Layer (`app/src/main/kotlin/`)
* **`BubbleManager.kt`**: Draggable floating bubble system window manager.
* **`BubbleService.kt`**: Foreground Service managing system alerts.
* **`SecureBubbleAccessibilityService.kt`**: Deep UI node tree link inspector and clean screen capture trigger.
* **`PopupManager.kt`**: Compact overlay popup UI displaying risk scores, threat categories, and VirusTotal reputation stats.
* **`OCRManager.kt`**: Google ML Kit Text Recognition with high-contrast dark mode binarization pass.
* **`QRManager.kt`**: Google ML Kit Barcode Scanning + ZXing `QRCodeReader` center-crop engine.
* **`LinkDetector.kt`**: URL scheme extractor, domain normalizer, and multi-line link re-joiner.
* **`RealThreatScanner.kt`**: On-device 0-100 risk scoring engine and VirusTotal API v3 adapter.

### 🌐 Threat Engine Backend Layer (`/backend/`)
* **`main.py`**: FastAPI server exposing:
  * `POST /api/v1/analyze/url`
  * `POST /api/v1/analyze/message`
* **`requirements.txt`**: Production dependencies (`fastapi`, `uvicorn`, `httpx`, `pydantic`).

---

## 4. Privacy & Defensive Security Rules

1. **Explicit On-Demand User Consent**: Screen capture occurs strictly when the user single-taps the floating security bubble. No silent background recording or keylogging.
2. **Local Processing Priority**: Heuristic rules, homograph scanning, and URL normalization are executed on-device.
3. **Credentials Exemption**: Passwords, OTPs, credit cards, and private tokens are automatically excluded from threat queries.
4. **API Key Isolation**: Cloud API credentials (such as VirusTotal API keys) are managed securely without hardcoding in production release builds.
