# Shirazi AI Desk App (شیرازی)

<div align="center">

![Shirazi AI Emblem](web/icons/Icon-192.png)

### **Autonomous Islamic Jurisprudence & Classical Fiqh Research System**

*An advanced multi-tiered scholarly AI application providing verified Fiqh reasoning, multi-madhhab research, and resilient fallback execution.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-gold.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Desktop%20%7C%20Android%20%7C%20Web-brightgreen)](https://flutter.dev)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-emerald)](https://github.com/TalhaGoharWeb/Shirazi-AI-Desk-App)

</div>

---

## 📖 Overview

**Shirazi AI Desk App** is a state-of-the-art academic and scholarly application designed for Islamic jurisprudence research, classical ruling inquiries (فتوى / مسائل فقهية), and multi-madhhab analysis.

Built with a **zero-hallucination mandate**, the system incorporates strict Madhhab isolation, grounded source verification via **RelevanceGuard**, and an automated **Multi-Tier BYOK (Bring Your Own Key)** fallback cascade to ensure uninterrupted availability even during high server load or offline states.

---

## ✨ Key Features

### 🏛️ Classical Fiqh & Madhhab Isolation
* **Strict Madhhab Scoping**: Enforces boundaries across **Hanafi (الحنفي)**, **Shafi'i (الشافعي)**, **Maliki (المالكي)**, and **Hanbali (الحنبلي)** legal frameworks.
* **No Cross-Contamination**: Prevents returning rulings from an incompatible Madhhab unless explicitly requested by the researcher.

### 🛡️ RelevanceGuard Zero-Hallucination Safeguard
* **Topic Entity Matching**: Validates retrieved content against the precise entity of the inquiry before presenting answers.
* **Grounded Source Notices**: If no verified classical source matches the query, the app honestly discloses the absence of verified sources rather than fabricating references.

### ⚡ Oracle-Only Answer Guarantee & BYOK Resilience
* **Tier 1 (Shirazi Core Socket)**: Real-time Socket.IO streaming from the primary Shirazi Research Engine (`http://129.154.242.136:4040`), with a research-realistic 150s window and live progress events.
* **Tier 2 (Server-Side BYOK)**: If the socket transport itself is unreachable, the same question is sent once over HTTP (`POST /api/chat`) — still to the Shirazi Oracle, which runs its full Shamela research / retrieval / verification pipeline using the user's key for inference.
* **Tier 3 (Canonical Fatwa Queue)**: Probes the Oracle's verified fatwa library for a topic-matched, madhhab-compatible scholarly answer.
* **Hard guarantee**: the app NEVER calls Groq / Gemini / OpenRouter (or any AI provider) directly. User keys are only ever transmitted to the Shirazi Oracle Server. If the Oracle cannot answer, the app shows an honest exhaustion notice and preserves the question for retry — it never substitutes a generic AI answer.

### 🌍 Tri-Lingual Academic Interface
* Native support for **Urdu (اردو)**, **Classical Arabic (العربية)**, and **Academic English (EN)**.
* Customized typography utilizing **Noto Nastaliq Urdu**, **Amiri Classical**, and **Noto Serif**.

### 🔒 User Data Privacy & Cloud Sync
* **Isolated Cloud Storage**: Firebase Firestore integration strictly isolated by user authentication (`ownerUid`).
* **Offline Local Vault**: Fully functional offline fallback mode storing research sessions locally when unauthenticated.

---

## 🛠️ Architecture & Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Framework** | Flutter 3.x (Desktop & Mobile) |
| **State Management** | Provider Architecture (`ChatProvider`, `SettingsProvider`, `AdminProvider`) |
| **Backend & Cloud** | Firebase Auth, Cloud Firestore (with strict Security Rules) |
| **Realtime Protocol** | WebSockets (`socket_io_client`), HTTP/2 REST |
| **AI LLM Providers** | Groq (LLaMA 3.3 70B Versatile), Google Gemini (1.5 Flash), OpenRouter AI |
| **Storage & Security** | SharedPreferences Local Vault with device-bound persistence |

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.19.0` or higher)
* [Dart SDK](https://dart.dev/get-dart) (`v3.3.0` or higher)
* Android Studio / VS Code with Flutter extension
* Optional: Personal API Key from [Groq Console](https://console.groq.com) or [Google AI Studio](https://aistudio.google.com)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/TalhaGoharWeb/Shirazi-AI-Desk-App.git
   cd Shirazi-AI-Desk-App
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   * **Windows Desktop**:
     ```bash
     flutter run -d windows
     ```
   * **Android Device / Emulator**:
     ```bash
     flutter run -d android
     ```
   * **Web**:
     ```bash
     flutter run -d chrome
     ```

---

## ⚙️ Setting Up Personal API Keys (BYOK)

To enable **Direct On-Device BYOK Failover**:

1. Open the app and navigate to **Settings (ترتیبات)** -> **Personal Key (BYOK)**.
2. Select your preferred provider (e.g. **Groq (LLaMA 3.3)** or **Gemini (Flash)**).
3. Paste your API key and tap **Save Key** / **Test Connection**.
4. Once verified, your app will automatically utilize your personal key if the primary server is offline or busy.

---

## 🧪 Testing & Verification

Run the automated test suite covering API resilience, localization, and Madhhab isolation:

```bash
flutter test
```

To run lint checks:

```bash
flutter analyze
```

---

## 📜 License

This project is released under the **MIT License**.

---

<div align="center">

Developed with reverence for classical Islamic jurisprudence & scholarly excellence.

</div>
