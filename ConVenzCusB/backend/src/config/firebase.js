import admin from "firebase-admin";
import { readFileSync } from "fs";
import { resolve } from "path";

let firebaseInitialized = false;

const initializeFirebase = () => {
  if (firebaseInitialized) return admin;

  try {
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "./firebase-service-account.json";
    const absolutePath = resolve(serviceAccountPath);
    const serviceAccount = JSON.parse(readFileSync(absolutePath, "utf8"));

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    firebaseInitialized = true;
    console.log(`✅ FIREBASE_INITIALIZED | Project: ${serviceAccount.project_id} | FCM Ready`);
  } catch (error) {
    console.error(`❌ FIREBASE_INIT_FAILED | Error: ${error.message} | Path: ${process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "./firebase-service-account.json"}`);
  }

  return admin;
};

// Initialize on module load
initializeFirebase();

export default admin;
