import express from "express";
import {
  createBooking,
  getUserBookings,
  updateBookingStatus,
  getBookingsByVendor,
  getBookingHistory
} from "../controllers/bookingController.js";
import { protect } from "../middlewares/authMiddleware.js";

const router = express.Router();

// 🔒 SERVER-TO-SERVER AUTH MIDDLEWARE
const serverProtect = (req, res, next) => {
  if (!process.env.SERVER_SECRET) {
    return res.status(500).json({ success: false, message: "Server misconfiguration: SERVER_SECRET not set" });
  }
  const serverSecret = req.headers['x-server-secret'];
  if (serverSecret && serverSecret === process.env.SERVER_SECRET) {
    return next();
  }
  return res.status(401).json({ success: false, message: "Unauthorized: Server-to-Server access required" });
};

/* ------------------------------------------
   📅 BOOKING ROUTES
------------------------------------------- */

// Customer creates a new booking
router.post("/create", protect, createBooking);

// Get all bookings for a specific user
router.get("/user/:userId", protect, getUserBookings);

// Vendor updates booking status (accept/reject/complete) - SERVER PROTECTED
router.patch("/update-status", serverProtect, updateBookingStatus);

// Get all bookings for a specific vendor - SERVER PROTECTED
router.get("/vendor/:vendorId", serverProtect, getBookingsByVendor);

// Get booking history with optional status filter
router.get("/history/:userId", protect, getBookingHistory);

export default router;
