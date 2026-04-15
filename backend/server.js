import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import compression from "compression";
import mongoSanitize from "express-mongo-sanitize";
import hpp from "hpp";
import mongoose from "mongoose";
import * as Sentry from "@sentry/node";

// Env loaded at absolute top
import connectDB from "./src/config/db.js";
import userRoutes from "./src/routes/userRoutes.js";
import subscriptionRoutes from "./src/routes/subscriptionRoutes.js";
import notificationRoutes from "./src/routes/notificationRoutes.js";
import externalRoutes from "./src/routes/externalRoutes.js";
import { notFound, errorHandler } from "./src/middlewares/errorMiddleware.js";
import startHourlyNotifications from "./src/utils/scheduler.js";
import logger from "./src/utils/logger.js";
import { verifySignature } from "./src/middlewares/sigMiddleware.js";

// Initialize Sentry for Error Tracking
if (process.env.SENTRY_DSN) {
  Sentry.init({ dsn: process.env.SENTRY_DSN });
  logger.info("🛡️  Sentry initialized for error monitoring");
}

// ✅ Connect to MongoDB (with retry logic in db.js)
connectDB();

// ✅ Initialize Scheduler AFTER DB connection attempt
startHourlyNotifications();

const app = express();

// ─────────────────────────────────────────────
// ☁️ Render Load Balancer / Proxy Support
// ─────────────────────────────────────────────
// Trust the first proxy to ensure `express-rate-limit` uses real client IPs
app.set("trust proxy", 1);

// ─────────────────────────────────────────────
// 🛡️ Security Middleware
// ─────────────────────────────────────────────
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://*.sentry.io"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      objectSrc: ["'none'"],
      upgradeInsecureRequests: [],
    },
  },
}));

app.use(morgan(process.env.NODE_ENV === "production" ? "combined" : "dev"));

// ─────────────────────────────────────────────
// 🚦 Rate Limiting (Prevent Brute Force / DoS)
// ─────────────────────────────────────────────
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: "Too many requests from this IP, please try again after 15 minutes",
  },
});
app.use("/api/", limiter);

// ─────────────────────────────────────────────
// 🌐 CORS — Restrict to known origins
// Mobile Flutter apps make direct API calls (no browser origin header),
// so they are unaffected by CORS policy. The restriction only blocks
// unauthorised browser-based clients.
// ─────────────────────────────────────────────
const ALLOWED_ORIGINS = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',').map((o) => o.trim())
  : [];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, server-to-server, curl)
    if (!origin) return callback(null, true);
    if (ALLOWED_ORIGINS.length === 0 || ALLOWED_ORIGINS.includes(origin)) {
      return callback(null, true);
    }
    callback(new Error(`CORS policy: origin ${origin} not allowed`));
  },
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization", "x-admin-secret", "x-server-secret", "x-cron-secret", "x-signature", "x-timestamp"],
  credentials: true,
}));

// ─────────────────────────────────────────────
// 📦 Body Parsing (with size limits for DoS protection)
// ─────────────────────────────────────────────
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Data Sanitization against NoSQL query injection
app.use(mongoSanitize());

// Prevent HTTP Parameter Pollution
app.use(/** @type {any} */ (hpp()));

// Response Compression (Gzip) for faster mobile loading
app.use(/** @type {any} */ (compression()));

// ─────────────────────────────────────────────
// 🛣️ API Routes
// ─────────────────────────────────────────────
app.use("/api/v1/user", verifySignature, userRoutes);
app.use("/api/v1/subscription", verifySignature, subscriptionRoutes);
app.use("/api/v1/notification", verifySignature, notificationRoutes);
app.use("/api/v1/external", verifySignature, externalRoutes);

// ─────────────────────────────────────────────
// 🩺 Health Check (For Render / Uptime Monitors)
// ─────────────────────────────────────────────
app.get("/health", (req, res) => {
  const dbState = ["disconnected", "connected", "connecting", "disconnecting"];
  res.status(200).json({
    status: "UP",
    environment: process.env.NODE_ENV || "production",
    timestamp: new Date().toISOString(),
    uptimeSeconds: Math.floor(process.uptime()),
    database: {
      state: dbState[mongoose.connection.readyState] || "unknown",
      connected: mongoose.connection.readyState === 1,
    },
  });
});

// ─────────────────────────────────────────────
// ❌ Global Error Handling (MUST be last)
// ─────────────────────────────────────────────
app.use(notFound);
app.use(errorHandler);

// ─────────────────────────────────────────────
// 🚀 Start Server
// ─────────────────────────────────────────────
const PORT = Number(process.env.PORT) || 5005;
const HOST = "0.0.0.0";

const server = app.listen(PORT, HOST, () => {
  logger.info("=".repeat(60));
  logger.info("🚀 CONVENZ CUSTOMER BACKEND SERVER — PRODUCTION");
  logger.info("=".repeat(60));
  logger.info(`✅ SERVER_STARTED   | ${new Date().toISOString()}`);
  logger.info(`📍 Port: ${PORT}    | Host: ${HOST}`);
  logger.info(`🌍 Environment: ${process.env.NODE_ENV || "production"}`);
  logger.info("=".repeat(60));
});

// ─────────────────────────────────────────────
// 🛑 Graceful Shutdown
// ─────────────────────────────────────────────
const gracefulShutdown = (signal) => {
  logger.info(`🛑 ${signal} received. Shutting down gracefully...`);
  server.close(async () => {
    logger.info("📡 HTTP server closed.");
    try {
      await mongoose.connection.close(false);
      logger.info("🗄️  MongoDB connection closed.");
      process.exit(0);
    } catch (err) {
      logger.error(err, "❌ Error closing MongoDB:");
      process.exit(1);
    }
  });
  // Force shutdown after 10 seconds
  setTimeout(() => {
    logger.error("⚠️  Forced shutdown after timeout.");
    process.exit(1);
  }, 10000);
};

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));
