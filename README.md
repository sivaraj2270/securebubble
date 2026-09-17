# 🛡️ SecureBubble AI — Autonomous Cyber Threat & Phishing Detection Platform

> **"SCAN BEFORE YOU CLICK"** — Autonomous, Privacy-First, Real-Time Phishing & Threat Prevention Engine for Android.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Kotlin](https://img.shields.io/badge/Kotlin-2.0-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)](https://kotlinlang.org)
[![Android 15 Ready](https://img.shields.io/badge/Android-15_Ready-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-API_v3-3949AB?style=for-the-badge&logo=virustotal&logoColor=white)](https://www.virustotal.com)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)

---

## 🌟 Overview

**SecureBubble AI** is an enterprise-grade cybersecurity application built with **Flutter + Kotlin** for Android. Designed around a layered defensive architecture (**Detect ➔ Analyze ➔ Explain ➔ Score ➔ Warn ➔ Protect ➔ Report ➔ Learn**), SecureBubble AI protects users from malicious destinations **before** they click or open any links or QR codes exposed on their screen.

---

## 🚀 Key Features

### 🫧 1. Cross-App "Scan Current Screen" (Pre-Click Defense)
- **Zero-Click Inspection**: Scans visible screen content across messaging & browsing apps (**WhatsApp, Telegram, SMS, Instagram, Chrome, Gmail, Discord**).
- **Accessibility & Node Tree Bounds**: Leverages Android `AccessibilityService` to extract URLs, package names, and exact screen rectangle coordinates (`left`, `top`, `right`, `bottom`).
- **QR Code Fallback**: Uses `MediaProjection` screen capture to detect and decode payment & disguised QR codes.
- **Combined Security Report**: Generates ONE unified report detailing safe, suspicious, and dangerous items.

### 🔮 2. AI Action Floating Security Orb
- Multi-spectral rainbow gradient aura ring (`Electric Blue`, `Purple`, `Amber`, `Emerald`), pitch-black center orb, and glowing white capsule eyes.
- Quick single-tap screen scanning and long-press radial security menu.

### 🛡️ 3. 0–100 Risk Engine & Active Threat Prevention
- Multi-layer analysis combining **VirusTotal API v3**, **Brand Impersonation Detection**, **Homograph / Punycode IDN Lookalikes**, **Deceptive Link Mismatch Inspector**, and **HTTP Redirect Chain Tracing**.
- Risk Scale Classifications:
  * `0 – 34`: 🟢 **SAFE**
  * `35 – 59`: 🟡 **SUSPICIOUS**
  * `60 – 79`: 🟠 **HIGH RISK**
  * `80 – 100`: 🔴 **DANGEROUS / CRITICAL**

### 🔒 4. Local VPN Firewall & Permanent Domain Blocklist
- Real Android `VpnService` domain filtering.
- One-tap permanent blocking for dangerous domains (`fake-bank.com`), enforcing local device-wide block rules for all subpaths (`fake-bank.com/login`, `fake-bank.com/account`).

### 🎨 5. Zentra Ambient Dark Glassmorphic UI
- Deep Midnight Obsidian background (`#070A12`) with GPU-accelerated ambient mesh aura light sources (`RepaintBoundary` optimized for 60 FPS performance).
- Geometric Hexagon Shield Logo & 4-Step First-Time User Stepper Setup.

---

## 🏗️ Technical Architecture

```text
Flutter UI / Floating Bubble Menu
                 │
                 │ MethodChannel ("nukezero/service" / "securebubble/security")
                 ▼
  SecureBubbleAccessibilityService (Android Native Kotlin)
                 │
                 ├── 1. ScreenContentExtractor (Accessibility Tree, URL Parsing, Rect Bounds)
                 ├── 2. QRManager & OCRManager (ML Kit Barcode Scanning & Text Recognition)
                 ├── 3. RealThreatScanner & VirusTotal Engine (0–100 Risk Scoring)
                 ├── 4. SecurityOverlayManager (🚨 Danger Badge Overlays on Screen Bounds)
                 └── 5. SecureBubbleVpnService & BlockedDomainManager (Local DNS Firewall)
```

---

## ⚡ Quick Start & Installation

### Prerequisites
- **Flutter SDK**: 3.x or higher
- **Android SDK**: API level 26+ (Tested & Ready on **Android 14 & Android 15**)
- **Java / JDK**: 17+

### 1. Clone Repository
```bash
git clone https://github.com/sivaraj2270/securebubble.git
cd securebubble
```

### 2. Configure API Keys
Copy your VirusTotal API Key and paste it into `lib/constants/api_keys.dart`:
```dart
class ApiKeys {
  static const String virusTotalApiKey = "YOUR_VIRUSTOTAL_API_KEY_HERE";
}
```

### 3. Install Dependencies & Run
```bash
flutter pub get
flutter run
```

### 4. Build Debug APK
```bash
flutter build apk --debug
```

---

## 🛡️ Security & Privacy First

- **On-Device Inspection**: Screen text and node URLs are parsed strictly upon explicit user tap. No continuous background screenshot logging or unauthorized data transmission.
- **Explicit Consent**: Screen capture permissions (`MediaProjection`) are requested only when explicitly selecting "Scan Current Screen".
- **Local Enforcement**: Domain blocking is performed 100% locally on device using Android's native `VpnService`.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
