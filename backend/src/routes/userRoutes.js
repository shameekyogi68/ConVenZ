import express from "express";
import rateLimit from "express-rate-limit";
import {
  registerUser,
  verifyOtp,
  updateUserDetails,
  updateUserLocation,
  createDefaultPlans,
  getAllPlans,
  getPlansByType,
  getPlanById,
  getUserProfile,
  updateUserProfile,
} from "../controllers/userController.js";
import { updateFcmToken } from "../controllers/notificationController.js";
import {
  createCustomerBooking,
  getUserBookings,
  getBookingDetails,
  cancelBooking,
  updateBookingStatus,
  verifyJobOtp,
  submitReview,
  mockAssignVendor,
  mockProgressBooking,
} from "../controllers/customerBookingController.js";
import {
  checkUserBlocked,
  blockUser,
  unblockUser,
  checkBlockStatus
} from "../middlewares/checkBlocked.js";
import { protect } from "../middlewares/authMiddleware.js";
import { validate, authSchemas, userSchemas, bookingSchemas, notificationSchemas } from "../middlewares/validateMiddleware.js";
import { idempotency } from "../middlewares/idempotencyMiddleware.js";

// Stricter rate limit for auth endpoints — prevents OTP brute force
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: "Too many attempts. Please try again after 15 minutes.",
  },
});

const router = express.Router();

// 🔒 ADMIN AUTH MIDDLEWARE
const adminProtect = (req, res, next) => {
  const adminSecret = req.headers['x-admin-secret'];
  if (!process.env.ADMIN_SECRET) {
    return res.status(500).json({ success: false, message: "Server misconfiguration: ADMIN_SECRET not set" });
  }
  if (adminSecret === process.env.ADMIN_SECRET) {
    next();
  } else {
    res.status(401).json({ success: false, message: "Unauthorized: Admin access required" });
  }
};

/* ------------------------------------------
   👤 USER ROUTES
   NOTE: Register and OTP verification do NOT have blocking middleware
   because blocking is checked AFTER user logs in
------------------------------------------- */
router.post("/register", authLimiter, validate(authSchemas.register), registerUser);
router.post("/user/register", authLimiter, validate(authSchemas.register), registerUser);
router.post("/verify-otp", authLimiter, validate(authSchemas.verifyOtp), checkUserBlocked, verifyOtp);
router.post("/user/verify-otp", authLimiter, validate(authSchemas.verifyOtp), checkUserBlocked, verifyOtp);

router.post("/update-user", protect, validate(userSchemas.updateProfile), checkUserBlocked, updateUserDetails);
router.post("/update-location", protect, validate(userSchemas.updateLocation), updateUserLocation); // Protected
router.post("/user/update-location", protect, validate(userSchemas.updateLocation), updateUserLocation); // Alias
router.post("/update-fcm-token", protect, validate(notificationSchemas.updateFcmToken), updateFcmToken);
router.post("/fcm/update-token", protect, validate(notificationSchemas.updateFcmToken), updateFcmToken);

router.get("/profile/:userId", protect, getUserProfile); // Protected
router.post("/profile/:userId", protect, checkUserBlocked, updateUserProfile); // Protected

// Profile aliases for Flutter
router.get("/user/profile/:userId", protect, getUserProfile); // Protected
router.post("/user/profile/:userId", protect, checkUserBlocked, updateUserProfile); // Protected

/* ------------------------------------------
   📅 BOOKING ROUTES (Customer Side)
   NOTE: Specific routes MUST come before parameterized routes
------------------------------------------- */
// 🔒 SERVER-TO-SERVER AUTH MIDDLEWARE (Used for Webhooks)
const serverProtect = (req, res, next) => {
  const serverSecret = req.headers['x-server-secret'];
  if (!process.env.SERVER_SECRET) {
    return res.status(500).json({ success: false, message: "Server misconfiguration: SERVER_SECRET not set" });
  }
  if (serverSecret === process.env.SERVER_SECRET) {
    next();
  } else {
    res.status(401).json({ success: false, message: "Unauthorized: Server-to-Server access required" });
  }
};

// Status update from vendor backend (Requires cross-server auth)
router.post(
  "/booking/status-update",
  serverProtect,
  idempotency(),
  validate(bookingSchemas.statusUpdate),
  updateBookingStatus
);

// Create booking - MUST come before :bookingId route
router.post("/booking/create", protect, validate(bookingSchemas.create), checkUserBlocked, createCustomerBooking);
router.post("/user/booking/create", protect, validate(bookingSchemas.create), checkUserBlocked, createCustomerBooking); // Alias

// Get all user bookings
router.get("/bookings/:userId", protect, checkUserBlocked, getUserBookings);
router.get("/user/bookings/:userId", protect, checkUserBlocked, getUserBookings); // Alias

// Cancel booking
router.post("/booking/:bookingId/cancel", protect, checkUserBlocked, cancelBooking);
router.post("/user/booking/:bookingId/cancel", protect, checkUserBlocked, cancelBooking); // Alias

// Verify Job Start OTP (Ensures vendor is present) - BLOCKER 3
router.post("/booking/:bookingId/verify-otp", protect, validate(bookingSchemas.verifyOtp), checkUserBlocked, verifyJobOtp);
router.post("/user/booking/:bookingId/verify-otp", protect, validate(bookingSchemas.verifyOtp), checkUserBlocked, verifyJobOtp); // Alias

// Rate Vendor (Review)
router.post("/booking/:bookingId/review", protect, validate(bookingSchemas.review), checkUserBlocked, submitReview);
router.post("/user/booking/:bookingId/review", protect, validate(bookingSchemas.review), checkUserBlocked, submitReview); // Alias

// Get single booking details - MUST come last (catches any bookingId)
router.get("/booking/:bookingId", protect, getBookingDetails);
router.get("/user/booking/:bookingId", protect, getBookingDetails); // Alias

// Mock assign vendor (QA/testing only)
router.post("/booking/:bookingId/mock-assign-vendor", protect, mockAssignVendor);
router.post("/user/booking/:bookingId/mock-assign-vendor", protect, mockAssignVendor); // Alias

router.post("/booking/:bookingId/mock-progress", protect, validate(bookingSchemas.mockProgress), mockProgressBooking);
router.post("/user/booking/:bookingId/mock-progress", protect, validate(bookingSchemas.mockProgress), mockProgressBooking); // Alias

/* ------------------------------------------
   🔒 ADMIN ROUTES - User Blocking (PROTECTED)
------------------------------------------- */
router.post("/admin/block-user", adminProtect, blockUser);
router.post("/admin/unblock-user", adminProtect, unblockUser);
router.get("/admin/check-status/:userId", adminProtect, checkBlockStatus);

/* ------------------------------------------
   💳 SUBSCRIPTION ROUTES
------------------------------------------- */
router.post("/create-plans", adminProtect, createDefaultPlans);
router.get("/plans/all", getPlansByType);
router.get("/plans", getAllPlans);
router.get("/plans/:id", getPlanById);

export default router;
