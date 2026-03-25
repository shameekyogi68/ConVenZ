# ConVenZ Monorepo

Welcome to the premium ConVenZ monorepo! This unified codebase houses both the Flutter customer application (APK) and the Node.js Express backend API. 

## 🏗 Architecture Overview

* **`ConVenzCusF/`**: The frontend application built in Flutter. Configured to build Android APKs seamlessly and deployed via GitHub Actions automatically on push.
* **`ConVenzCusB/backend/`**: The backend API server built in Node.js. It connects to MongoDB and Firebase and is configured purely for Render deployment.
* **`render.yaml`**: The automated Infrastructure-as-Code (IaC) file that defines the Render environment mapping directly into the backend folder.
* **`.github/workflows/build_apk.yml`**: Automates CI/CD for building release APKs of the frontend customer application on every push to the `main` branch.

## 🚀 Getting Started

### Backend
1. Navigate to the backend directory: `cd ConVenzCusB/backend`
2. Install dependencies: `npm install`
3. Start the server locally: `npm run dev`

### Frontend (Flutter)
1. Navigate to the frontend directory: `cd ConVenzCusF`
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

## 🔒 Security

All secret `.env` keys, `google-services.json`, `firebase-service-account.json`, and heavy items like `node_modules` or `build/` files are perfectly isolated and ignored strictly from source control via the root `.gitignore`. Ensure you grab these securely from your team lead to run the app locally!
