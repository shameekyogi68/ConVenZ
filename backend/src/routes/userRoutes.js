import express from "express";
import {
  registerUser,
  verifyOtp,
  updateUserDetails,
  updateVendorLocation,
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
  updateBookingStatus
} from "../controllers/customerBookingController.js";
import {
  checkUserBlocked,
  blockUser,
  unblockUser,
  checkBlockStatus
} from "../middlewares/checkBlocked.js";
import { protect } from "../middlewares/authMiddleware.js";
import { validate, authSchemas, userSchemas, bookingSchemas } from "../middlewares/validateMiddleware.js";

const router = express.Router();

// 🔒 ADMIN AUTH MIDDLEWARE
const adminProtect = (req, res, next) => {
  const adminSecret = req.headers['x-admin-secret'];
  if (adminSecret === process.env.ADMIN_SECRET || adminSecret === 'convenz_admin_2024_secret') {
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
router.post("/register", validate(authSchemas.register), registerUser); // No blocking check - allow registration
router.post("/user/register", validate(authSchemas.register), registerUser); // Alias for Flutter app compatibility
router.post("/verify-otp", validate(authSchemas.verifyOtp), checkUserBlocked, verifyOtp); // Check block status during login
router.post("/user/verify-otp", validate(authSchemas.verifyOtp), checkUserBlocked, verifyOtp); // Alias for Flutter app compatibility

router.post("/update-user", protect, validate(userSchemas.updateProfile), checkUserBlocked, updateUserDetails);
router.post("/update-location", protect, validate(userSchemas.updateLocation), updateVendorLocation); // Protected
router.post("/user/update-location", protect, validate(userSchemas.updateLocation), updateVendorLocation); // Alias
router.post("/update-fcm-token", protect, updateFcmToken); // Protected
router.post("/fcm/update-token", protect, updateFcmToken); // Clean alias for Flutter

router.get("/profile/:userId", protect, getUserProfile); // Protected
router.post("/profile/:userId", protect, checkUserBlocked, updateUserProfile); // Protected

// Profile aliases for Flutter
router.get("/user/profile/:userId", protect, getUserProfile); // Protected
router.post("/user/profile/:userId", protect, checkUserBlocked, updateUserProfile); // Protected

/* ------------------------------------------
   📅 BOOKING ROUTES (Customer Side)
   NOTE: Specific routes MUST come before parameterized routes
------------------------------------------- */
// Status update from vendor backend (no blocking check - comes from vendor)
router.post("/booking/status-update", updateBookingStatus);

// Create booking - MUST come before :bookingId route
router.post("/booking/create", protect, validate(bookingSchemas.create), checkUserBlocked, createCustomerBooking);
router.post("/user/booking/create", protect, validate(bookingSchemas.create), checkUserBlocked, createCustomerBooking); // Alias

// Get all user bookings
router.get("/bookings/:userId", protect, checkUserBlocked, getUserBookings);
router.get("/user/bookings/:userId", protect, checkUserBlocked, getUserBookings); // Alias

// Cancel booking
router.post("/booking/:bookingId/cancel", protect, checkUserBlocked, cancelBooking);
router.post("/user/booking/:bookingId/cancel", protect, checkUserBlocked, cancelBooking); // Alias

// Get single booking details - MUST come last (catches any bookingId)
router.get("/booking/:bookingId", protect, getBookingDetails);
router.get("/user/booking/:bookingId", protect, getBookingDetails); // Alias

/* ------------------------------------------
   🔒 ADMIN ROUTES - User Blocking (PROTECTED)
------------------------------------------- */
router.post("/admin/block-user", adminProtect, blockUser);
router.post("/admin/unblock-user", adminProtect, unblockUser);
router.get("/admin/check-status/:userId", adminProtect, checkBlockStatus);

/* ------------------------------------------
   💳 SUBSCRIPTION ROUTES
------------------------------------------- */
router.post("/create-plans", createDefaultPlans);
router.get("/plans/all", getPlansByType);
router.get("/plans", getAllPlans);
router.get("/plans/:id", getPlanById);

export default router;
