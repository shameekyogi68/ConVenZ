import Booking from "../models/bookingModel.js";
import User from "../models/userModel.js";
import Vendor from "../models/vendorModel.js";
import { findBestVendor } from "../utils/vendorMatcherFixed.js";
import { sendNotification, sendMultipleNotifications } from "../utils/sendNotification.js";
import asyncHandler from "../utils/asyncHandler.js";
import mongoose from "mongoose";

/* Helper: fetch vendor details from raw vendors collection */
const getVendorDetails = async (vendorId) => {
  if (!vendorId) return null;

  const vendorsCollection = mongoose.connection.db.collection('vendors');
  const vendor = await vendorsCollection.findOne({
    $or: [
      { vendorId: vendorId },
      { _id: typeof vendorId === 'string' ? new mongoose.Types.ObjectId(vendorId) : vendorId }
    ]
  });

  if (!vendor) return null;

  return {
    id: vendor.vendorId || vendor._id.toString(),
    name: vendor.vendorName || vendor.businessName,
    phone: vendor.mobile,
    rating: vendor.rating || 0,
    fcmTokens: vendor.fcmTokens || []
  };
};

/* ------------------------------------------------------------
   📝 CREATE NEW BOOKING WITH VENDOR MATCHING
------------------------------------------------------------ */
export const createBooking = asyncHandler(async (req, res) => {
  const { selectedService, jobDescription, date, time, location } = req.body;
  const userId = req.user.user_id;

  const user = await User.findOne({ user_id: userId });
  if (!user) {
    res.status(404);
    throw new Error("User not found");
  }

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
    status: "pending",
  });

  console.log(`✅ BOOKING_CREATED | ID: ${newBooking.booking_id} | Service: ${selectedService}`);

  const vendorMatch = await findBestVendor(selectedService, location.latitude, location.longitude, 50);

  if (!vendorMatch) {
    if (user.fcmToken) {
      sendNotification(
        user.fcmToken,
        "⚠️ No Vendor Available",
        `Sorry, no ${selectedService} vendor is available right now. We'll notify you when one becomes available.`,
        { type: "BOOKING_STATUS", bookingId: String(newBooking.booking_id), status: "pending" }
      ).catch(() => {});
    }
    return res.status(201).json({
      success: true,
      message: "Booking created, searching for a vendor",
      data: newBooking,
      bookingId: newBooking.booking_id,
      vendorFound: false,
    });
  }

  newBooking.vendorId = vendorMatch.vendor.vendor_id;
  newBooking.distance = vendorMatch.distance;
  await newBooking.save();

  console.log(`✅ VENDOR_ASSIGNED | Vendor: ${vendorMatch.vendor.vendor_id} | Distance: ${vendorMatch.distance}km`);

  if (vendorMatch.vendor.fcmTokens?.length > 0) {
    sendMultipleNotifications(
      vendorMatch.vendor.fcmTokens,
      "🔔 New Service Request",
      `${user.name || 'A customer'} needs ${selectedService} at ${time} on ${date}. Distance: ${vendorMatch.distance}km`,
      {
        type: "NEW_BOOKING",
        bookingId: String(newBooking.booking_id),
        vendorId: String(vendorMatch.vendor.vendor_id),
        service: selectedService,
        date, time,
        address: location.address,
        distance: String(vendorMatch.distance),
        customerName: user.name || "Customer",
      }
    ).catch(() => {});
  }

  if (user.fcmToken) {
    sendNotification(
      user.fcmToken,
      "✅ Booking Confirmed",
      `Your ${selectedService} request has been sent to ${vendorMatch.vendor.name}. Waiting for vendor acceptance.`,
      { type: "BOOKING_CONFIRMATION", bookingId: String(newBooking.booking_id), service: selectedService }
    ).catch(() => {});
  }

  return res.status(201).json({
    success: true,
    message: "Booking created and vendor notified",
    data: newBooking,
    bookingId: newBooking.booking_id,
    vendorFound: true,
    vendor: {
      id: vendorMatch.vendor.vendor_id,
      name: vendorMatch.vendor.name,
      distance: vendorMatch.distance,
    },
  });
});

/* ------------------------------------------------------------
   👤 GET USER BOOKINGS
------------------------------------------------------------ */
export const getUserBookings = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;
  const bookings = await Booking.find({ userId }).sort({ createdAt: -1 });

  const enrichedBookings = await Promise.all(
    bookings.map(async (booking) => {
      const vendorDetails = await getVendorDetails(booking.vendorId);
      return { ...booking.toObject(), vendor: vendorDetails };
    })
  );

  return res.status(200).json({ success: true, count: bookings.length, data: enrichedBookings });
});

/* ------------------------------------------------------------
   🔄 UPDATE BOOKING STATUS (VENDOR ACTION)
------------------------------------------------------------ */
export const updateBookingStatus = asyncHandler(async (req, res) => {
  const { bookingId } = req.params;
  const { status, vendorId } = req.body;

  const booking = await Booking.findOne({ booking_id: bookingId });
  if (!booking) {
    res.status(404);
    throw new Error("Booking not found");
  }

  if (vendorId && booking.vendorId !== vendorId) {
    res.status(403);
    throw new Error("Not authorized to update this booking");
  }

  const customer = await User.findOne({ user_id: booking.userId });
  if (!customer) {
    res.status(404);
    throw new Error("Customer not found");
  }

  const vendor = await getVendorDetails(booking.vendorId);

  if (status === "accepted") {
    const otp = Math.floor(1000 + Math.random() * 9000);
    booking.otpStart = otp;
    booking.status = "accepted";
    await booking.save();

    console.log(`✅ BOOKING_ACCEPTED | ID: ${bookingId}`);

    if (customer.fcmToken) {
      sendNotification(
        customer.fcmToken,
        "✅ Booking Accepted!",
        `${vendor?.name || 'Your vendor'} accepted your ${booking.selectedService} request. Your service OTP is ${otp}`,
        { type: "BOOKING_STATUS_UPDATE", bookingId: String(bookingId), status: "accepted", otp: String(otp), service: booking.selectedService }
      ).catch(() => {});
    }

    if (vendor?.fcmTokens?.length > 0) {
      sendMultipleNotifications(
        vendor.fcmTokens,
        "✅ You Accepted the Booking",
        `Customer OTP: ${otp}. Service: ${booking.selectedService} at ${booking.time}`,
        { type: "BOOKING_ACCEPTED_CONFIRMATION", bookingId: String(bookingId), otp: String(otp) }
      ).catch(() => {});
    }

    return res.status(200).json({
      success: true,
      message: "Booking accepted",
      data: booking,
      otp: booking.otpStart,
    });
  }

  if (status === "rejected") {
    booking.status = "rejected";
    await booking.save();
    console.log(`❌ BOOKING_REJECTED | ID: ${bookingId}`);

    if (customer.fcmToken) {
      sendNotification(
        customer.fcmToken,
        "❌ Booking Declined",
        `${vendor?.name || 'The vendor'} declined your ${booking.selectedService} request. We'll find you another vendor.`,
        { type: "BOOKING_STATUS_UPDATE", bookingId: String(bookingId), status: "rejected" }
      ).catch(() => {});
    }

    return res.status(200).json({ success: true, message: "Booking rejected", data: booking });
  }

  if (status === "completed") {
    booking.status = "completed";
    await booking.save();
    console.log(`✅ BOOKING_COMPLETED | ID: ${bookingId}`);

    if (vendor) {
      const vendorsCollection = mongoose.connection.db.collection('vendors');
      await vendorsCollection.updateOne(
        { $or: [{ vendorId: vendor.id }, { _id: new mongoose.Types.ObjectId(vendor.id) }] },
        { $inc: { totalBookings: 1, completedBookings: 1 } }
      );
    }

    if (customer.fcmToken) {
      sendNotification(
        customer.fcmToken,
        "🎉 Service Completed!",
        `Your ${booking.selectedService} service has been completed. Thank you for using ConVenZ!`,
        { type: "BOOKING_STATUS_UPDATE", bookingId: String(bookingId), status: "completed" }
      ).catch(() => {});
    }

    return res.status(200).json({ success: true, message: "Booking completed", data: booking });
  }

  res.status(400);
  throw new Error(`Invalid status transition: ${status}`);
});

/* ------------------------------------------------------------
   🏢 GET BOOKINGS BY VENDOR
------------------------------------------------------------ */
export const getBookingsByVendor = asyncHandler(async (req, res) => {
  const { vendorId } = req.params;
  const bookings = await Booking.find({ vendorId }).sort({ createdAt: -1 });

  const enrichedBookings = await Promise.all(
    bookings.map(async (booking) => {
      const customer = await User.findOne({ user_id: booking.userId });
      return {
        ...booking.toObject(),
        customer: customer
          ? { id: customer.user_id, name: customer.name }
          : null,
      };
    })
  );

  return res.status(200).json({ success: true, count: bookings.length, data: enrichedBookings });
});

/* ------------------------------------------------------------
   📜 BOOKING HISTORY (Filterable by status)
------------------------------------------------------------ */
export const getBookingHistory = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;
  const { status } = req.query;

  const filter = { userId };
  if (status) filter.status = status;

  const bookings = await Booking.find(filter).sort({ createdAt: -1 });

  const enrichedBookings = await Promise.all(
    bookings.map(async (booking) => {
      const vendorDetails = await getVendorDetails(booking.vendorId);
      return { ...booking.toObject(), vendor: vendorDetails };
    })
  );

  return res.status(200).json({ success: true, count: bookings.length, data: enrichedBookings });
});
