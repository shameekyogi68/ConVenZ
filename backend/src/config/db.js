import mongoose from "mongoose";
import { seedDefaultPlansIfEmpty } from "../utils/seedPlans.js";

// Fail fast on queries when the DB is not connected.
// Without this, Mongoose silently buffers operations and they execute
// once (if ever) the connection is restored — masking real failures.
mongoose.set("bufferCommands", false);

// Suppress Mongoose 7 strictQuery deprecation warning
mongoose.set("strictQuery", false);

const MAX_RETRIES = 5;
const BASE_DELAY_MS = 2000; // doubles each attempt: 2s, 4s, 8s, 16s, 32s

// ── Connection event logging ──────────────────────────────────
mongoose.connection.on("connected", () =>
  console.log(`✅ MongoDB connected | DB: ${mongoose.connection.name}`)
);

// Seed minimum subscription plans for production UX.
mongoose.connection.on("connected", () => {
  seedDefaultPlansIfEmpty().catch(() => {});
});
mongoose.connection.on("disconnected", () =>
  console.warn("⚠️  MongoDB disconnected — waiting for reconnect")
);
mongoose.connection.on("reconnected", () =>
  console.log("✅ MongoDB reconnected")
);
mongoose.connection.on("error", (err) =>
  console.error(`❌ MongoDB connection error: ${err.message}`)
);

/**
 * Connect to MongoDB with exponential-backoff retry.
 * Exits the process only after all retries are exhausted —
 * transient network blips on startup (e.g. container cold-start)
 * are handled automatically.
 */
const connectDB = async (attempt = 1) => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      // How long the driver waits to find a primary before throwing
      serverSelectionTimeoutMS: 10_000,
      // Connection pool — tuned for a single-instance API server
      maxPoolSize: 10,
      minPoolSize: 2,
      // Abort an in-flight socket operation after 45 s
      socketTimeoutMS: 45_000,
    });
    // "connected" event above handles the success log
  } catch (err) {
    const delay = BASE_DELAY_MS * 2 ** (attempt - 1);
    console.error(
      `❌ MongoDB connection failed (attempt ${attempt}/${MAX_RETRIES}): ${err.message}`
    );

    if (attempt < MAX_RETRIES) {
      console.log(`⏳ Retrying in ${delay / 1000}s…`);
      await new Promise((resolve) => setTimeout(resolve, delay));
      return connectDB(attempt + 1);
    }

    console.error("🚨 All MongoDB connection attempts exhausted. Exiting.");
    process.exit(1);
  }
};

export default connectDB;
