import axios from "axios";
import Booking from "../models/bookingModel.js";
import User from "../models/userModel.js";
import { findBestVendor } from "../utils/vendorMatcherFixed.js";
import { sendNotification } from "../utils/sendNotification.js";
import Vendor from "../models/vendorModel.js";
import asyncHandler from "../utils/asyncHandler.js";
import logger from "../utils/logger.js";

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
    // UX-first: instead of blocking the flow, return the most recent active booking
    // so the app can continue to vendor-search/tracking screens seamlessly.
    const existing = await Booking.findOne({
      userId,
      status: { $in: ["pending", "accepted", "enroute"] },
    }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      message: "You already have an active booking in progress.",
      data: existing,
      reusedExisting: true,
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

  logger.info(`✅ BOOKING_CREATED | ID: ${newBooking.booking_id}`);

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
  // select +otpStart so the Flutter OTP screen can display the code
  const booking = await Booking.findOne({ booking_id: req.params.bookingId }).select("+otpStart");
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
    accepted: ["enroute", "completed", "cancelled", "rejected"],
    enroute: ["completed", "cancelled"],
    completed: [],
    cancelled: [],
    rejected: []
  };

  if (!validTransitions[booking.status] || !validTransitions[booking.status].includes(status)) {
    res.status(400);
    throw new Error(`Invalid status transition from ${booking.status} to ${status}`);
  }

  // @ts-ignore: String is not assignable to exact enum type
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
   🧪 MOCK: ASSIGN A TEST VENDOR (Customer-only, for QA)
------------------------------------------------------------ */
export const mockAssignVendor = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;
  const bookingId = req.params.bookingId;

  const booking = await Booking.findOne({ booking_id: bookingId });
  if (!booking) {
    return res.status(404).json({ success: false, message: "Booking not found" });
  }

  if (booking.userId !== userId) {
    return res.status(403).json({ success: false, message: "Access denied" });
  }

  if (["completed", "cancelled"].includes(booking.status)) {
    return res.status(400).json({ success: false, message: `Cannot assign vendor for status: ${booking.status}` });
  }

  // Ensure mock vendor exists in database
  await ensureMockVendorExists();

  // Assign a deterministic mock vendor and mark accepted.
  booking.vendorId = 9999;
  booking.status = "accepted";
  booking.otpStart = Math.floor(1000 + Math.random() * 9000);
  booking.distance = 0;
  booking.externalVendor = {
    vendorId: "MOCK-9999",
    vendorName: "Mock Vendor",
    vendorPhone: "9999999999",
    vendorAddress: booking.location?.address ?? "",
    serviceType: booking.selectedService,
    assignedAt: new Date(),
    lastUpdated: new Date(),
  };
  await booking.save();

  logger.info(`MOCK_VENDOR_ASSIGNED | Booking: ${bookingId} | User: ${userId} | Vendor: Mock Vendor | Status: accepted`);

  // Get customer details for notification
  const customer = await User.findOne({ user_id: userId });
  
  // Send notification to customer (same as real vendor acceptance)
  if (customer?.fcmToken) {
    sendNotification(
      customer.fcmToken,
      "✅ Booking Accepted!",
      `Your ${booking.selectedService} request was accepted by Mock Vendor. Open app to view your OTP.`,
      { type: "BOOKING_STATUS_UPDATE", bookingId, status: "accepted" }
    )
      .then(() => logger.info(`MOCK_VENDOR_ASSIGNMENT_NOTIFICATION_SENT | User: ${userId} | Booking: ${bookingId}`))
      .catch((err) => logger.error(`MOCK_VENDOR_ASSIGNMENT_NOTIFICATION_FAILED | User: ${userId} | Booking: ${bookingId} | Error: ${err.message}`));
  } else {
    logger.warn(`NO_FCM_TOKEN_FOR_MOCK_ASSIGNMENT | User: ${userId} | Booking: ${bookingId}`);
  }

  // Fetch booking with OTP included for frontend
  const bookingWithOtp = await Booking.findOne({ booking_id: bookingId }).select("+otpStart");

  return res.status(200).json({
    success: true,
    message: "Mock vendor assigned",
    data: bookingWithOtp,
  });
});

/* ------------------------------------------------------------
   🧪 ENSURE MOCK VENDOR EXISTS IN DATABASE
------------------------------------------------------------ */
async function ensureMockVendorExists() {
  try {
    const existingVendor = await Vendor.findOne({ vendor_id: 9999 });
    if (existingVendor) {
      logger.info(`MOCK_VENDOR_ALREADY_EXISTS | Vendor: 9999`);
      return;
    }

    // Create mock vendor if doesn't exist
    const mockVendor = await Vendor.create({
      vendor_id: 9999,
      name: "Mock Vendor",
      phone: 9999999999,
      email: "mockvendor@convenz.test",
      address: "Mock Vendor Address, Test City",
      location: {
        type: "Point",
        coordinates: [0, 0], // Default coordinates
      },
      selectedServices: ["General Cleaning", "Deep Cleaning", "Office Cleaning"],
      fcmTokens: [],
      rating: 4.5,
      totalBookings: 0,
      completedBookings: 0,
      totalRating: 0,
      isOnline: true,
    });

    logger.info(`MOCK_VENDOR_CREATED | Vendor: 9999 | Name: Mock Vendor | ID: ${mockVendor._id}`);
  } catch (error) {
    logger.error(`MOCK_VENDOR_CREATION_FAILED | Error: ${error.message}`);
  }
}

/* ------------------------------------------------------------
   🧪 MOCK: PROGRESS BOOKING STATUS (Customer-only, for QA)
------------------------------------------------------------ */
export const mockProgressBooking = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;
  const bookingId = req.params.bookingId;
  const { status } = req.body;

  const booking = await Booking.findOne({ booking_id: bookingId });
  if (!booking) {
    return res.status(404).json({ success: false, message: "Booking not found" });
  }
  if (booking.userId !== userId) {
    return res.status(403).json({ success: false, message: "Access denied" });
  }
  if (booking.vendorId !== 9999) {
    return res.status(400).json({ success: false, message: "Mock progression is only allowed for mock vendor bookings" });
  }

  const next = String(status || "").toLowerCase();
  if (!["enroute", "completed"].includes(next)) {
    return res.status(400).json({ success: false, message: "Invalid mock status. Use enroute or completed." });
  }

  if (!booking.otpStart) {
    booking.otpStart = Math.floor(1000 + Math.random() * 9000);
  }

  // Simple allowed transitions for mock
  if (next === "enroute" && !["accepted", "pending", "enroute"].includes(booking.status)) {
    return res.status(400).json({ success: false, message: `Cannot move to enroute from ${booking.status}` });
  }
  if (next === "completed" && !["accepted", "enroute"].includes(booking.status)) {
    return res.status(400).json({ success: false, message: `Cannot move to completed from ${booking.status}` });
  }

  // @ts-ignore: String is not assignable to exact enum type
  booking.status = next;
  await booking.save();

  return res.status(200).json({ success: true, message: "Mock status updated", data: booking });
});

/* ------------------------------------------------------------
   🔑 VERIFY JOB OTP (Service Start Confirmation)
   BLOCKER 3: Ensures vendor is physically present
------------------------------------------------------------ */
export const verifyJobOtp = asyncHandler(async (req, res) => {
  const bookingId = req.params.bookingId || req.body.bookingId;
  const { otp } = req.body;
  const userId = req.user.user_id;

  if (!bookingId) {
    res.status(400);
    throw new Error("bookingId is required");
  }

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

  logger.info(`✅ JOB_STARTED | Booking: ${booking.booking_id} | Customer: ${userId}`);

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
      logger.info(`⭐ VENDOR_RATING_UPDATED | Vendor: ${vendor.vendor_id} | New Rating: ${vendor.rating}`);
    }
  }

  return res.status(200).json({ success: true, message: "Review submitted successfully" });
});
