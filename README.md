# ConVenZ Monorepo

Welcome to the premium ConVenZ monorepo! This unified codebase houses perfectly separated frontend and backend directories.

## 🏗 Architecture Overview

* **`frontend/`**: The frontend customer application built in Flutter. Configured to build Android APKs seamlessly via GitHub Actions on every push.
* **`backend/`**: The backend API server built natively in Node.js. It connects to MongoDB and Firebase and is strictly configured for Render deployment.
* **`render.yaml`**: The automated Infrastructure-as-Code (IaC) file that defines the Render environment mapped directly entirely to the `backend/` folder.
* **`.github/workflows/build_apk.yml`**: Automates CI/CD for building reliable release APKs of the customer application completely automatically on every push to the `main` branch.

## 🚀 Getting Started

### Master Setup
At the root directory, install all global dependencies at once:
```bash
npm run setup:all
```

### Backend
1. Start the actual server locally: `npm run dev:backend`

### Frontend (Flutter)
1. Navigate to the frontend directory: `cd frontend`
2. Run the application logic: `flutter run`

## 🔒 Security & Git Ignore

All error-prone and heavy files like `node_modules`, `build/`, `.DS_Store`, and especially strict `.env` variables and `firebase-service-account.json` keys are mathematically ignored by the master `.gitignore` to keep this repository explicitly error-free and safely completely synchronized!
