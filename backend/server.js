import "dotenv/config";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import compression from "compression";
import crypto from "crypto";
import mongoose from "mongoose";
import * as Sentry from "@sentry/node";
import jwt from "jsonwebtoken";

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
// 🧾 Request correlation + basic access logs
// ─────────────────────────────────────────────// Enhanced request correlation + user activity logging
app.use((req, res, next) => {
  const id = crypto.randomUUID();
  /** @type {any} */ (req).id = id;
  res.setHeader("x-request-id", id);

  const start = Date.now();
  const timestamp = new Date().toISOString();
  
  // Extract user info from JWT if available
  let userInfo = null;
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.substring(7);
      const decoded = jwt.decode(token);
      if (decoded && typeof decoded === 'object' && decoded.userId) {
        userInfo = {
          userId: decoded.userId,
          phone: decoded.phone,
          role: decoded.role || 'customer'
        };
      }
    } catch {
      // Token decode failed - continue without user info
    }
  }

  // Enhanced activity logging
  res.on("finish", () => {
    const duration = Date.now() - start;
    const logData = {
      event: "USER_ACTIVITY",
      id,
      timestamp,
      method: req.method,
      path: req.originalUrl,
      endpoint: req.route?.path || req.path,
      statusCode: res.statusCode,
      durationMs: duration,
      ip: req.ip,
      userAgent: req.headers["user-agent"],
      contentType: req.headers["content-type"],
      contentLength: req.headers["content-length"],
      success: res.statusCode < 400,
      ...(userInfo && { user: userInfo }),
      // Activity categorization
      category: getActivityCategory(req.method, req.originalUrl),
      // Additional context
      isHealthCheck: req.originalUrl === '/health' || req.originalUrl === '/',
      isApiCall: req.originalUrl.startsWith('/api/'),
      environment: process.env.NODE_ENV || 'production'
    };

    // Use appropriate log level based on status and importance
    if (res.statusCode >= 500) {
      logger.error(logData, `SERVER ERROR: ${req.method} ${req.originalUrl}`);
    } else if (res.statusCode >= 400) {
      logger.warn(logData, `CLIENT ERROR: ${req.method} ${req.originalUrl}`);
    } else if (userInfo) {
      logger.info(logData, `USER ACTIVITY: ${req.method} ${req.originalUrl} by ${userInfo.phone || userInfo.userId}`);
    } else {
      logger.info(logData, `API CALL: ${req.method} ${req.originalUrl}`);
    }
  });

  next();
});

// Helper function to categorize activities
function getActivityCategory(method, path) {
  if (path === '/health' || path === '/') return 'HEALTH_CHECK';
  if (path.includes('/auth/')) return 'AUTHENTICATION';
  if (path.includes('/user/')) return 'USER_MANAGEMENT';
  if (path.includes('/booking/')) return 'BOOKING';
  if (path.includes('/subscription/')) return 'SUBSCRIPTION';
  if (path.includes('/notification/')) return 'NOTIFICATION';
  if (path.includes('/external/')) return 'EXTERNAL_INTEGRATION';
  if (method === 'POST') return 'DATA_CREATION';
  if (method === 'PUT' || method === 'PATCH') return 'DATA_UPDATE';
  if (method === 'DELETE') return 'DATA_DELETION';
  return 'DATA_RETRIEVAL';
}

// ─────────────────────────────────────────────
// 🧩 Express v5 compatibility shim
// ─────────────────────────────────────────────
// Some third-party middleware (or older code) may still try to assign to `req.query`.
// assignments throw and can break health checks (e.g. Render's `HEAD /` probe).
app.use((req, _res, next) => {
  try {
    const desc = Object.getOwnPropertyDescriptor(req, "query");
    if (!desc || typeof desc.set !== "function") {
      const q = req.query; // capture getter value once
      Object.defineProperty(req, "query", {
        value: q,
        writable: true,
        enumerable: true,
        configurable: true,
      });
    }
  } catch {
    // ignore and continue
  }
  next();
});

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

// Data Sanitization and Parameter Pollution protection disabled for Node v25 compatibility
// We use Joi (validateMiddleware) which handles this logic safely during route validation.

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
app.head("/", (req, res) => {
  res.status(200).end();
});

app.get("/", (req, res) => {
  res.status(200).json({ status: "alive", message: "ConVenZ API is running" });
});

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
