import Booking from "../models/bookingModel.js";
import User from "../models/userModel.js";
import { sendNotification } from "../utils/sendNotification.js";
import asyncHandler from "../utils/asyncHandler.js";
import logger from "../utils/logger.js";

/* ------------------------------------------------------------
   🔄 EXTERNAL VENDOR UPDATE CALLBACK
   ELITE VERSION: Clean, Secure, and Standardized
------------------------------------------------------------ */
export const receiveVendorUpdate = asyncHandler(async (req, res) => {
  // ✅ 1. Auth Validation
  if (!process.env.VENDOR_SECRET) {
    res.status(500);
    throw new Error('Server misconfiguration: VENDOR_SECRET not set');
  }
  const vendorSecret = req.headers['x-vendor-secret'];
  if (!vendorSecret || vendorSecret !== process.env.VENDOR_SECRET) {
    res.status(401);
    throw new Error('Unauthorized: Invalid vendor secret');
  }

  // ✅ 2. Extract Data
  const { vendorId, vendorName, vendorPhone, vendorAddress, serviceType, assignedOrderId, status } = req.body;

  // Manual check for critical external fields (or could use Joi)
  if (!assignedOrderId || !status || !vendorName) {
    res.status(400);
    throw new Error('Missing required callback fields: assignedOrderId, status, vendorName');
  }

  // ✅ 3. Update Booking
  const booking = await Booking.findOne({ booking_id: parseInt(assignedOrderId) });
  if (!booking) {
    res.status(404);
    throw new Error(`Booking ID ${assignedOrderId} not found`);
  }

  // Update Status & Details
  booking.externalVendor = {
    vendorId: String(vendorId),
    vendorName: String(vendorName),
    vendorPhone: String(vendorPhone),
    vendorAddress: String(vendorAddress),
    serviceType: String(serviceType),
    lastUpdated: new Date(),
    assignedAt: booking.externalVendor?.assignedAt || new Date()
  };

  // ✅ BLOCKER 6: Status machine validation
  const validTransitions = {
    pending: ["accepted", "rejected", "cancelled"],
    accepted: ["enroute", "rejected", "cancelled"],
    enroute: ["completed", "cancelled"],
    rejected: [],
    completed: [],
    cancelled: []
  };

  const newStatus = status.toLowerCase();
  const allowed = validTransitions[booking.status] || [];

  if (!allowed.includes(newStatus)) {
    res.status(400);
    throw new Error(`Invalid status transition from "${booking.status}" to "${newStatus}"`);
  }

  booking.status = newStatus;
  await booking.save();

  logger.info(`✅ EXTERNAL_CALLBACK_SUCCESS | Booking: ${booking.booking_id} | Status: ${booking.status}`);

  // ✅ 4. Notify Customer (Non-blocking)
  const customer = await User.findOne({ user_id: booking.userId });
  if (customer?.fcmToken) {
    let title = '📢 Booking Update';
    let body = `Your booking status has been updated to: ${status}`;
    
    if (status.toLowerCase() === 'accepted') {
      title = '✅ Vendor Found!';
      body = `${vendorName} has accepted your ${booking.selectedService} request.`;
    } else if (status.toLowerCase() === 'enroute') {
      title = '🚗 Vendor On The Way';
      body = `${vendorName} is heading to your location.`;
    }

    sendNotification(customer.fcmToken, title, body, { type: 'VENDOR_UPDATE', bookingId: String(booking.booking_id), status: booking.status }).catch(() => {});
  }

  return res.status(200).json({
    success: true,
    message: 'Vendor update processed',
    data: { bookingId: booking.booking_id, status: booking.status }
  });
});
