# 🛡️ Aegis AI Phishing Detector

An advanced AI-powered multi-vector threat detection and real-time phishing classification platform combining Natural Language Processing (NLP) heuristics and Machine Learning (ML) ensemble classifiers.

---

## 🚀 Live Deployments

- **🌐 Live Web Application (Frontend):** [https://aegis-phishing-detector-six.vercel.app](https://aegis-phishing-detector-six.vercel.app)
- **⚡ Live Cloud API (FastAPI Backend):** [https://ai-phishing-detector-backend.onrender.com](https://ai-phishing-detector-backend.onrender.com)
- **📖 Interactive API Docs (Swagger UI):** [https://ai-phishing-detector-backend.onrender.com/docs](https://ai-phishing-detector-backend.onrender.com/docs)

---

## ✨ Key Features

1. **Multi-Vector Threat Scanning:**
   - 🔗 **URL Phishing Scanner**: Domain age, entropy, IP masking, spoofed brand keywords, malicious TLD detection.
   - 💬 **SMS / Text Scam Scanner**: Social engineering heuristics, urgent financial traps, spam phrase analysis.
   - 📧 **Email Header Scanner**: Spoofed sender domains, SPF/DKIM verification indicators, credential harvesting alerts.
   - 🖼️ **Screenshot Vision Scanner**: Visual inspection of fraudulent landing pages and fake login portals.
   - 🚫 **Spam Classifier**: Real-time message intent classification.

2. **Hybrid Detection Engine (NLP + Machine Learning):**
   - **NLP Rule Engine:** Instant heuristic pattern matching for urgent keywords, deceptive syntax, and whitelists.
   - **ML Ensemble Training:** Real-time dataset training with Random Forest, Support Vector Machines (SVM), Decision Trees, Logistic Regression, and XGBoost.
   - **Explainable AI (XAI):** Detailed risk score breakdown with specific threat indicators and actionable advice.

3. **Per-User Scoped Workspaces & Telemetry:**
   - Isolated scan history and analytics per user account.
   - Dedicated ML training states and customized model checkpoints.

---

## 🏗️ Architecture & Tech Stack

- **Frontend / Mobile:** Flutter (Web & Android APK) with Provider state management and Material UI.
- **Backend API:** FastAPI (Python 3.11 asynchronous REST API).
- **ML & Data Processing:** scikit-learn, pandas, numpy, TF-IDF vectorizers.
- **Database:** SQLite with SQLAlchemy ORM.
- **Hosting & CI/CD:** Vercel (Frontend Web) & Render Cloud (Backend Web Service).

---

## 🚀 Running Locally

### 1. Backend (FastAPI Python)
```bash
cd backend
python -m venv venv
# Windows:
.\venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 2. Frontend / Mobile (Flutter)
```bash
cd mobile
flutter pub get

# Run on Web:
flutter run -d chrome

# Run on Android Device / Emulator:
flutter run

# Build Android APK:
flutter build apk --release
```

---

## 📱 Android APK Build
To build a standalone installable Android APK on your local machine:
```bash
cd mobile
flutter build apk --release
```
The resulting `.apk` file will be generated at `mobile/build/app/outputs/flutter-apk/app-release.apk`.
