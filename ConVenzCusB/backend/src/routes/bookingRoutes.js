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

/* ------------------------------------------
   📅 BOOKING ROUTES
------------------------------------------- */

// Customer creates a new booking
router.post("/create", protect, createBooking);

// Get all bookings for a specific user
router.get("/user/:userId", protect, getUserBookings);

// Vendor updates booking status (accept/reject/complete)
router.patch("/update-status", updateBookingStatus);

// Get all bookings for a specific vendor
router.get("/vendor/:vendorId", getBookingsByVendor);

// Get booking history with optional status filter
router.get("/history/:userId", protect, getBookingHistory);

export default router;
