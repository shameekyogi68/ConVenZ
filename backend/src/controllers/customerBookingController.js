import axios from "axios";
import Booking from "../models/bookingModel.js";
import User from "../models/userModel.js";
import { findBestVendor } from "../utils/vendorMatcherFixed.js";
import { sendNotification } from "../utils/sendNotification.js";
import Vendor from "../models/vendorModel.js";
import asyncHandler from "../utils/asyncHandler.js";

/* ------------------------------------------------------------
   📝 CREATE BOOKING & NOTIFY VENDOR BACKEND
------------------------------------------------------------ */
export const createCustomerBooking = asyncHandler(async (req, res) => {
  const { selectedService, jobDescription, date, time, location } = req.body;
  const userId = req.user.user_id; // Secure from token

  // Verify customer
  const customer = await User.findOne({ user_id: userId });
  if (!customer) {
    res.status(404);
    throw new Error("Customer not found");
  }

  // ✅ BLOCKER 4: Prevent unlimited simultaneous pending bookings
  const activePending = await Booking.countDocuments({
    userId,
    status: { $in: ["pending", "accepted", "enroute"] }
  });
  
  if (activePending >= 1) {
    return res.status(400).json({
      success: false,
      message: "You already have an active booking in progress. Please complete or cancel it first.",
    });
  }

  // Create booking
  const newBooking = await Booking.create({
    userId,
    selectedService,
    jobDescription,
    date,
    time,
    location: {
      type: "Point",
      coordinates: [location.longitude, location.latitude],
      address: location.address
    },
    status: "pending"
  });

  console.log(`✅ BOOKING_CREATED | ID: ${newBooking.booking_id}`);

  // FIRE-AND-FORGET: External Vendor Notifications
  const externalVendorUrl = process.env.EXTERNAL_VENDOR_URL || 'https://convenz-vendor-dor.vercel.app/api/external/orders';
  const webserverVendorUrl = process.env.WEBSERVER_VENDOR_URL || 'https://webserver-vendor.vercel.app/api/external/orders';
  
  const payload = {
    bookingId: newBooking.booking_id,
    customerId: userId,
    customerName: customer.name || "Customer",
    customerPhone: String(customer.phone),
    service: selectedService,
    description: jobDescription,
    location: { latitude: location.latitude, longitude: location.longitude, address: location.address }
  };

  // Notify External Servers (Non-blocking)
  axios.post(externalVendorUrl, payload, { timeout: 10000 }).catch(() => {});
  axios.post(webserverVendorUrl, payload, { headers: { 'x-customer-secret': process.env.WEBSERVER_VENDOR_SECRET || '' }, timeout: 10000 }).catch(() => {});

  // Find Internal Vendor
  const vendorMatch = await findBestVendor(selectedService, location.latitude, location.longitude, 50);

  if (!vendorMatch) {
    if (customer.fcmToken) {
      // Don't alarm the user immediately; we're still searching/dispatching on external vendor systems.
      sendNotification(
        customer.fcmToken,
        "🔎 Searching for a vendor",
        `We’re looking for nearby ${selectedService} vendors. You’ll be notified once someone accepts.`,
        { type: "SEARCHING_VENDOR", bookingId: String(newBooking.booking_id) }
      ).catch(() => {});
    }
    return res.status(201).json({ success: true, message: "Booking created, searching for vendor...", data: newBooking, vendorFound: false });
  }

  // Update with Vendor
  newBooking.vendorId = vendorMatch.vendor.vendor_id;
  newBooking.distance = vendorMatch.distance;
  await newBooking.save();

  // Notify Vendor (Non-blocking)
  const vendorBackendUrl = process.env.VENDOR_BACKEND_URL || 'https://vendor-backend-7cn3.onrender.app';
  axios.post(`${vendorBackendUrl}/vendor/api/new-booking`, { ...payload, vendorId: vendorMatch.vendor.vendor_id }, { timeout: 10000 }).catch(() => {});

  if (vendorMatch.vendor.fcmTokens?.length > 0) {
    sendNotification(vendorMatch.vendor.fcmTokens[0], "🔔 New Service Request", `New ${selectedService} request near you!`, { type: "NEW_BOOKING", bookingId: String(newBooking.booking_id) }).catch(() => {});
  }

  // Notify Customer
  if (customer.fcmToken) {
    sendNotification(customer.fcmToken, "✅ Booking Processed", `Your ${selectedService} request is being handled by ${vendorMatch.vendor.name}.`, { type: "BOOKING_CONFIRMATION", bookingId: String(newBooking.booking_id) }).catch(() => {});
  }

  return res.status(201).json({
    success: true,
    message: "Booking created and vendor matched",
    data: newBooking,
    vendor: { id: vendorMatch.vendor.vendor_id, name: vendorMatch.vendor.name, distance: vendorMatch.distance }
  });
});

/* ------------------------------------------------------------
   📋 GET USER'S BOOKINGS
------------------------------------------------------------ */
export const getUserBookings = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;

  // Validate the URL param matches the authenticated user
  if (req.params.userId && req.params.userId !== userId) {
    res.status(403);
    throw new Error("You can only query your own bookings");
  }

  // Limit queries to the last 90 days to prevent full collection scans on old users
  const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
  const bookings = await Booking.find({ userId, createdAt: { $gte: ninetyDaysAgo } }).sort({ createdAt: -1 }).limit(50);
  return res.status(200).json({ success: true, count: bookings.length, data: bookings });
});

/* ------------------------------------------------------------
   🔍 GET SINGLE BOOKING DETAILS
------------------------------------------------------------ */
export const getBookingDetails = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;
  const booking = await Booking.findOne({ booking_id: req.params.bookingId });
  if (!booking) {
    res.status(404);
    throw new Error("Booking not found");
  }
  if (booking.userId !== userId) {
    res.status(403);
    throw new Error("Access denied");
  }
  return res.status(200).json({ success: true, data: booking });
});

/* ------------------------------------------------------------
   ❌ CANCEL BOOKING
------------------------------------------------------------ */
export const cancelBooking = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;
  const booking = await Booking.findOne({ booking_id: req.params.bookingId });

  if (!booking) {
    res.status(404);
    throw new Error("Booking not found");
  }

  if (booking.userId !== userId) {
    res.status(403);
    throw new Error("Unauthorized to cancel this booking");
  }

  if (["completed", "cancelled"].includes(booking.status)) {
    res.status(400);
    throw new Error(`Cannot cancel booking with status: ${booking.status}`);
  }

  booking.status = "cancelled";
  await booking.save();

  return res.status(200).json({ success: true, message: "Booking cancelled successfully", data: booking });
});

/* ------------------------------------------------------------
   🔄 BOOKING STATUS UPDATE (FROM VENDOR)
------------------------------------------------------------ */
export const updateBookingStatus = asyncHandler(async (req, res) => {
  const { bookingId, status, vendorId, otpStart, rejectionReason } = req.body;
  const booking = await Booking.findOne({ booking_id: bookingId });

  if (!booking) {
    res.status(404);
    throw new Error("Booking not found");
  }

  const validTransitions = {
    pending: ["accepted", "rejected", "cancelled"],
    accepted: ["completed", "cancelled", "rejected"],
    completed: [],
    cancelled: [],
    rejected: []
  };

  if (!validTransitions[booking.status] || !validTransitions[booking.status].includes(status)) {
    res.status(400);
    throw new Error(`Invalid status transition from ${booking.status} to ${status}`);
  }

  booking.status = status;
  if (status === "accepted" && otpStart) booking.otpStart = otpStart;
  if (vendorId) booking.vendorId = vendorId;
  if (status === "rejected" && rejectionReason) booking.rejectionReason = rejectionReason;
  await booking.save();

  // Notify customer
  const customer = await User.findOne({ user_id: booking.userId });
  if (customer?.fcmToken) {
    let title = "Booking Update";
    let body = `Your booking status is now: ${status}`;
    if (status === "accepted") {
      title = "✅ Booking Accepted!";
      body = `Your ${booking.selectedService} request was accepted. Open the app to view your OTP.`;
    }
    sendNotification(customer.fcmToken, title, body, { type: "BOOKING_STATUS_UPDATE", bookingId, status }).catch(() => {});
  }

  return res.status(200).json({ success: true, message: "Status updated", data: booking });
});

/* ------------------------------------------------------------
   🔑 VERIFY JOB OTP (Service Start Confirmation)
   BLOCKER 3: Ensures vendor is physically present
------------------------------------------------------------ */
export const verifyJobOtp = asyncHandler(async (req, res) => {
  const { bookingId, otp } = req.body;
  const userId = req.user.user_id;

  // Find booking and include otpStart (select: false in schema)
  const booking = await Booking.findOne({ booking_id: bookingId }).select("+otpStart");

  if (!booking) {
    res.status(404);
    throw new Error("Booking not found");
  }

  if (booking.userId !== userId) {
    res.status(403);
    throw new Error("You are not authorized to verify this booking");
  }

  if (booking.status !== "accepted" && booking.status !== "enroute") {
    res.status(400);
    throw new Error(`OTP verification not available for status: ${booking.status}`);
  }

  if (parseInt(otp) !== booking.otpStart) {
    res.status(400);
    throw new Error("Invalid start OTP. Please check with your vendor.");
  }

  // Transition to enroute or virtual "in_progress" (mapped to enroute for now)
  // Or handle as a successful checkpoint before completion
  booking.status = "enroute"; // If enroute, it stays enroute but verified
  await booking.save();

  console.log(`✅ JOB_STARTED | Booking: ${booking.booking_id} | Customer: ${userId}`);

  return res.status(200).json({
    success: true,
    message: "Service start verified successfully. Vendor may now proceed.",
    status: booking.status
  });
});

/* ------------------------------------------------------------
   ⭐ RATE VENDOR (Submit Review)
------------------------------------------------------------ */
export const submitReview = asyncHandler(async (req, res) => {
  const { rating, reviewText } = req.body;
  const bookingId = req.params.bookingId;
  const userId = req.user.user_id;

  const booking = await Booking.findOne({ booking_id: bookingId });
  if (!booking) {
    res.status(404);
    throw new Error("Booking not found");
  }

  if (booking.userId !== userId) {
    res.status(403);
    throw new Error("Unauthorized to review this booking");
  }

  if (booking.status !== "completed") {
    res.status(400);
    throw new Error("Can only review completed bookings");
  }

  if (booking.rating) {
    res.status(400);
    throw new Error("Review already submitted for this booking");
  }

  if (!rating || rating < 1 || rating > 5) {
    res.status(400);
    throw new Error("Invalid rating. Must be between 1 and 5.");
  }

  booking.rating = rating;
  booking.review = reviewText;
  await booking.save();

  // ✅ Update Vendor's Average Rating
  if (booking.vendorId) {
    const vendor = await Vendor.findOne({ vendor_id: booking.vendorId });
    if (vendor) {
      vendor.completedBookings = (vendor.completedBookings || 0) + 1;
      vendor.totalRating = (vendor.totalRating || 0) + rating;
      vendor.rating = parseFloat((vendor.totalRating / vendor.completedBookings).toFixed(2));
      await vendor.save();
      console.log(`⭐ VENDOR_RATING_UPDATED | Vendor: ${vendor.vendor_id} | New Rating: ${vendor.rating}`);
    }
  }

  return res.status(200).json({ success: true, message: "Review submitted successfully" });
});
