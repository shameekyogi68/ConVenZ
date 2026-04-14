import admin from "firebase-admin";
import { readFileSync } from "fs";
import { resolve } from "path";

let firebaseInitialized = false;

const initializeFirebase = () => {
  if (firebaseInitialized) return admin;

  try {
    let serviceAccount;
    
    // Support loading from direct JSON string in Env Var (Good for Render)
    if (process.env.FIREBASE_CONFIG_JSON) {
      serviceAccount = JSON.parse(process.env.FIREBASE_CONFIG_JSON);
    } else {
      const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "./firebase-service-account.json";
      const absolutePath = resolve(serviceAccountPath);
      serviceAccount = JSON.parse(readFileSync(absolutePath, "utf8"));
    }

    if (!serviceAccount) throw new Error("Firebase configuration not found.");

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    firebaseInitialized = true;
    console.log(`✅ FIREBASE_INITIALIZED | Project: ${serviceAccount.project_id} | FCM Ready`);
  } catch (error) {
    const source = process.env.FIREBASE_CONFIG_JSON ? "Env JSON" : (process.env.FIREBASE_SERVICE_ACCOUNT_PATH || "./firebase-service-account.json");
    console.error(`❌ FIREBASE_INIT_FAILED | Error: ${error.message} | Source: ${source}`);
    console.warn(`⚠️  Firebase is NOT initialized. Push notifications will fail. Server will continue running.`);
    // Do not exit the process, so the Express server can still bind and serve API health checks
  }

  return admin;
};

// Initialize on module load
initializeFirebase();

export default admin;
