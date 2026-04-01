import mongoose from "mongoose";

const MAX_RETRIES = 5;
const RETRY_DELAY_MS = 5000;

/**
 * Connect to MongoDB with automatic retry on failure.
 * This prevents the server from dying on a single transient network error.
 */
const connectDB = async (attempt = 1) => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 10000, // Fail fast if server is unreachable
    });
    console.log(`✅ MongoDB Connected | Host: ${conn.connection.host} | DB: ${conn.connection.name}`);
  } catch (err) {
    console.error(`❌ MongoDB Connection Failed (Attempt ${attempt}/${MAX_RETRIES}): ${err.message}`);
    if (attempt < MAX_RETRIES) {
      console.log(`⏳ Retrying in ${RETRY_DELAY_MS / 1000}s...`);
      setTimeout(() => connectDB(attempt + 1), RETRY_DELAY_MS);
    } else {
      console.error("🚨 All MongoDB connection attempts failed. Exiting process.");
      process.exit(1);
    }
  }
};

export default connectDB;
