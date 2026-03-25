import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import connectDB from "./src/config/db.js";
import userRoutes from "./src/routes/userRoutes.js";
import bookingRoutes from "./src/routes/bookingRoutes.js";
import subscriptionRoutes from "./src/routes/subscriptionRoutes.js";
import notificationRoutes from "./src/routes/notificationRoutes.js";
import externalRoutes from "./src/routes/externalRoutes.js";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import { notFound, errorHandler } from "./src/middlewares/errorMiddleware.js";

// Load environment variables
dotenv.config();

// Connect to MongoDB
connectDB();

const app = express();

// 🛡️ Security Middleware
app.use(helmet()); // Sets various HTTP headers for security
app.use(morgan("dev")); // Modern request logging

// 🚦 Rate Limiting (Prevent Brute Force)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    success: false,
    message: "Too many requests from this IP, please try again after 15 minutes",
  },
});
app.use("/api/", limiter);


// Middleware - CORS Configuration for Mobile Apps
app.use(cors({
  origin: '*', // Allow all origins for mobile Flutter apps
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API Routes
app.use("/api/user", userRoutes);
app.use("/api/booking", bookingRoutes);
app.use("/api/subscription", subscriptionRoutes);
app.use("/api/notification", notificationRoutes);
app.use("/api/external", externalRoutes);

// Error Handling Middlewares
app.use(notFound);
app.use(errorHandler);

// Start Server
const PORT = process.env.PORT || 5005;
const HOST = '0.0.0.0'; // Required for Render deployment

app.listen(PORT, HOST, () => {
  console.log('\n' + '='.repeat(60));
  console.log('🚀 CONVENZ CUSTOMER BACKEND SERVER');
  console.log('='.repeat(60));
  console.log(`✅ SERVER_STARTED | ${new Date().toISOString()}`);
  console.log(`📍 Port: ${PORT} | Host: ${HOST}`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Base URL: http://${HOST}:${PORT}`);
  console.log('='.repeat(60) + '\n');
});
