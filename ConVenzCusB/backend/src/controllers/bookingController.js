import Booking from "../models/bookingModel.js";
import User from "../models/userModel.js";
import Vendor from "../models/vendorModel.js";
import { findBestVendor } from "../utils/vendorMatcherFixed.js";
import { sendNotification, sendMultipleNotifications } from "../utils/sendNotification.js";
import mongoose from "mongoose";

/* Helper function to get vendor details from existing schema */
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
export const createBooking = async (req, res) => {
  try {
    console.log('\n📅 === CREATE BOOKING REQUEST ===');
    console.log('📦 Request Body:', JSON.stringify(req.body, null, 2));
    
    // const { userId, selectedService, jobDescription, date, time, location } = req.body;
    const { selectedService, jobDescription, date, time, location } = req.body;
    const userId = req.user.user_id; // Secure token-based ID

    // Validation
    if (!userId || !selectedService || !jobDescription || !date || !time || !location) {
      console.log('❌ Missing required fields');
      return res.status(400).json({
        success: false,
        message: "Missing required fields: userId, selectedService, jobDescription, date, time, location"
      });
    }

    if (!location.latitude || !location.longitude || !location.address) {
      console.log('❌ Invalid location data');
      return res.status(400).json({
        success: false,
        message: "Location must include latitude, longitude, and address"
      });
    }

    // Verify user exists
    const user = await User.findOne({ user_id: userId });
    if (!user) {
      console.log(`❌ User ${userId} not found`);
      return res.status(404).json({
        success: false,
        message: "User not found"
      });
    }

    console.log(`✅ Customer: ${user.name || user.phone} (ID: ${userId})`);

    // Step 1: Create booking with pending status
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
      otpStart: null,
      vendorId: null,
      distance: null
    });

    console.log(`✅ BOOKING_CREATED | ${new Date().toISOString()} | Booking ID: ${newBooking.booking_id} | Status: pending`);

    // Step 2: Find best vendor
    const vendorMatch = await findBestVendor(
      selectedService,
      location.latitude,
      location.longitude,
      50 // 50km radius
    );

    if (!vendorMatch) {
      console.log('⚠️  NO_VENDOR_AVAILABLE | Booking created but no vendor found');
      
      // Notify customer that no vendor is available
      if (user.fcmToken) {
        try {
          await sendNotification(
            user.fcmToken,
            "⚠️ No Vendor Available",
            `Sorry, no vendor is available for ${selectedService} right now. We'll notify you when one becomes available.`,
            { 
              type: "BOOKING_STATUS",
              bookingId: String(newBooking.booking_id),
              status: "pending"
            }
          );
        } catch (error) {
          console.log(`⚠️  Failed to send notification to customer: ${error.message}`);
        }
      }

      return res.status(200).json({
        success: true,
        message: "Booking created but no vendor available at the moment",
        data: newBooking,
        bookingId: newBooking.booking_id,
        vendorFound: false
      });
    }

    // Step 3: Update booking with vendor details
    newBooking.vendorId = vendorMatch.vendor.vendor_id;
    newBooking.distance = vendorMatch.distance;
    await newBooking.save();

    console.log(`✅ VENDOR_ASSIGNED | Vendor: ${vendorMatch.vendor.name} (ID: ${vendorMatch.vendor.vendor_id}) | Distance: ${vendorMatch.distance}km`);

    // Step 4: Send FCM notification to vendor
    if (vendorMatch.vendor.fcmTokens && vendorMatch.vendor.fcmTokens.length > 0) {
      try {
        const notificationData = {
          type: "NEW_BOOKING",
          bookingId: String(newBooking.booking_id),
          vendorId: String(vendorMatch.vendor.vendor_id),
          userId: String(userId),
          service: selectedService,
          date: date,
          time: time,
          address: location.address,
          distance: String(vendorMatch.distance),
          customerName: user.name || "Customer",
          customerPhone: String(user.phone)
        };

        const response = await sendMultipleNotifications(
          vendorMatch.vendor.fcmTokens,
          "🔔 New Service Request",
          `${user.name || 'A customer'} needs ${selectedService} at ${time} on ${date}. Distance: ${vendorMatch.distance}km`,
          notificationData
        );

        console.log(`📲 VENDOR_NOTIFIED | ${new Date().toISOString()} | Vendor: ${vendorMatch.vendor.vendor_id} | Sent: ${response.successCount}/${vendorMatch.vendor.fcmTokens.length}`);
      } catch (error) {
        console.log(`⚠️  VENDOR_NOTIFICATION_FAILED | ${new Date().toISOString()} | Error: ${error.message}`);
      }
    } else {
      console.log(`⚠️  NO_VENDOR_FCM_TOKENS | Vendor ${vendorMatch.vendor.vendor_id} has no FCM tokens`);
    }

    // Step 5: Send confirmation to customer
    if (user.fcmToken) {
      try {
        await sendNotification(
          user.fcmToken,
          "✅ Booking Confirmed",
          `Your ${selectedService} request has been sent to ${vendorMatch.vendor.name}. Waiting for vendor acceptance.`,
          {
            type: "BOOKING_CONFIRMATION",
            bookingId: String(newBooking.booking_id),
            vendorName: vendorMatch.vendor.name || "Vendor",
            service: selectedService
          }
        );
        console.log(`📲 CUSTOMER_NOTIFIED | ${new Date().toISOString()} | User: ${userId}`);
      } catch (error) {
        console.log(`⚠️  CUSTOMER_NOTIFICATION_FAILED | ${new Date().toISOString()} | Error: ${error.message}`);
      }
    }

    console.log('='.repeat(50));

    return res.status(201).json({
      success: true,
      message: "Booking created and vendor notified",
      data: newBooking,
      bookingId: newBooking.booking_id,
      vendorFound: true,
      vendor: {
        id: vendorMatch.vendor.vendor_id,
        name: vendorMatch.vendor.name,
        distance: vendorMatch.distance
      }
    });

  } catch (error) {
    console.error("❌ CREATE_BOOKING_ERROR:", error.message);
    return res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
};

/* ------------------------------------------------------------
   👤 GET USER BOOKINGS
------------------------------------------------------------ */
export const getUserBookings = async (req, res) => {
  try {
    console.log('\n👤 === GET USER BOOKINGS ===');
    const userId = req.user.user_id; // Secure token-based ID
    console.log(`🔍 Fetching bookings for user: ${userId}`);

    const bookings = await Booking.find({ userId }).sort({ createdAt: -1 });

    // Enrich with vendor details
    const enrichedBookings = await Promise.all(
      bookings.map(async (booking) => {
        const vendorDetails = await getVendorDetails(booking.vendorId);
        return {
          ...booking.toObject(),
          vendor: vendorDetails
        };
      })
    );

    console.log(`✅ Found ${bookings.length} bookings`);
    console.log('='.repeat(50));

    return res.status(200).json({
      success: true,
      count: bookings.length,
      data: enrichedBookings
    });

  } catch (err) {
    console.error("❌ GET_USER_BOOKINGS_ERROR:", err.message);
    return res.status(500).json({ 
      success: false, 
      message: err.message 
    });
  }
};

/* ------------------------------------------------------------
   🔄 UPDATE BOOKING STATUS (VENDOR ACTION)
------------------------------------------------------------ */
export const updateBookingStatus = async (req, res) => {
  try {
    console.log('\n🔄 === UPDATE BOOKING STATUS ===');
    const { bookingId } = req.params;
    const { status, vendorId } = req.body;

    console.log(`📋 Booking ID: ${bookingId}`);
    console.log(`🏢 Vendor ID: ${vendorId}`);
    console.log(`📊 New Status: ${status}`);

    // Validation
    if (!status) {
      console.log('❌ Status is required');
      return res.status(400).json({ 
        success: false, 
        message: "Status is required" 
      });
    }

    if (!["accepted", "rejected", "completed"].includes(status)) {
      console.log('❌ Invalid status');
      return res.status(400).json({
        success: false,
        message: "Status must be: accepted, rejected, or completed"
      });
    }

    // Find booking
    const booking = await Booking.findOne({ booking_id: bookingId });

    if (!booking) {
      console.log(`❌ Booking ${bookingId} not found`);
      return res.status(404).json({ 
        success: false, 
        message: "Booking not found" 
      });
    }

    // Verify vendor owns this booking
    if (vendorId && booking.vendorId !== vendorId) {
      console.log(`❌ Vendor ${vendorId} not authorized for booking ${bookingId}`);
      return res.status(403).json({
        success: false,
        message: "Not authorized to update this booking"
      });
    }

    // Get customer info
    const customer = await User.findOne({ user_id: booking.userId });
    if (!customer) {
      console.log(`❌ Customer ${booking.userId} not found`);
      return res.status(404).json({
        success: false,
        message: "Customer not found"
      });
    }

    // Get vendor info
    const vendor = await getVendorDetails(booking.vendorId);

    // Handle status-specific logic
    if (status === "accepted") {
      // Generate 4-digit OTP
      const otp = Math.floor(1000 + Math.random() * 9000);
      booking.otpStart = otp;
      booking.status = "accepted";
      await booking.save();

      console.log(`✅ BOOKING_ACCEPTED | ${new Date().toISOString()} | Booking: ${bookingId} | OTP: ${otp}`);

      // Send OTP notification to customer
      if (customer.fcmToken) {
        try {
          await sendNotification(
            customer.fcmToken,
            "✅ Booking Accepted!",
            `${vendor?.name || 'Vendor'} accepted your ${booking.selectedService} request. Your service OTP is ${otp}`,
            {
              type: "BOOKING_STATUS_UPDATE",
              bookingId: String(bookingId),
              status: "accepted",
              otp: String(otp),
              vendorName: vendor?.name || "Vendor",
              service: booking.selectedService,
              date: booking.date,
              time: booking.time
            }
          );
          console.log(`📲 OTP_SENT_TO_CUSTOMER | ${new Date().toISOString()} | User: ${customer.user_id} | OTP: ${otp}`);
        } catch (error) {
          console.log(`⚠️  CUSTOMER_NOTIFICATION_FAILED | ${new Date().toISOString()} | Error: ${error.message}`);
        }
      }

      // Notify vendor of acceptance
      if (vendor && vendor.fcmTokens && vendor.fcmTokens.length > 0) {
        try {
          await sendMultipleNotifications(
            vendor.fcmTokens,
            "✅ You Accepted the Booking",
            `Booking confirmed! Customer OTP: ${otp}. Service: ${booking.selectedService} at ${booking.time}`,
            {
              type: "BOOKING_ACCEPTED_CONFIRMATION",
              bookingId: String(bookingId),
              otp: String(otp),
              customerName: customer.name || "Customer",
              customerPhone: String(customer.phone)
            }
          );
          console.log(`📲 VENDOR_CONFIRMATION_SENT | ${new Date().toISOString()} | Vendor: ${vendor.vendor_id}`);
        } catch (error) {
          console.log(`⚠️  VENDOR_NOTIFICATION_FAILED | ${new Date().toISOString()} | Error: ${error.message}`);
        }
      }

    } else if (status === "rejected") {
      booking.status = "rejected";
      await booking.save();

      console.log(`❌ BOOKING_REJECTED | ${new Date().toISOString()} | Booking: ${bookingId}`);

      // Notify customer of rejection
      if (customer.fcmToken) {
        try {
          await sendNotification(
            customer.fcmToken,
            "❌ Booking Declined",
            `${vendor?.name || 'The vendor'} declined your ${booking.selectedService} request. We'll find you another vendor.`,
            {
              type: "BOOKING_STATUS_UPDATE",
              bookingId: String(bookingId),
              status: "rejected",
              service: booking.selectedService
            }
          );
          console.log(`📲 REJECTION_SENT_TO_CUSTOMER | ${new Date().toISOString()} | User: ${customer.user_id}`);
        } catch (error) {
          console.log(`⚠️  CUSTOMER_NOTIFICATION_FAILED | ${new Date().toISOString()} | Error: ${error.message}`);
        }
      }

    } else if (status === "completed") {
      booking.status = "completed";
      await booking.save();

      console.log(`✅ BOOKING_COMPLETED | ${new Date().toISOString()} | Booking: ${bookingId}`);

      // Update vendor stats
      if (vendor) {
        const vendorsCollection = mongoose.connection.db.collection('vendors');
        await vendorsCollection.updateOne(
          { $or: [{ vendorId: vendor.id }, { _id: new mongoose.Types.ObjectId(vendor.id) }] },
          { 
            $inc: { 
              totalBookings: 1,
              completedBookings: 1
            }
          }
        );
        console.log(`📊 VENDOR_STATS_UPDATED | Vendor: ${vendor.id} | Stats incremented`);
      }

      // Notify customer of completion
      if (customer.fcmToken) {
        try {
          await sendNotification(
            customer.fcmToken,
            "🎉 Service Completed!",
            `Your ${booking.selectedService} service has been completed by ${vendor?.name || 'the vendor'}. Thank you for using our service!`,
            {
              type: "BOOKING_STATUS_UPDATE",
              bookingId: String(bookingId),
              status: "completed",
              service: booking.selectedService
            }
          );
          console.log(`📲 COMPLETION_SENT_TO_CUSTOMER | ${new Date().toISOString()} | User: ${customer.user_id}`);
        } catch (error) {
          console.log(`⚠️  CUSTOMER_NOTIFICATION_FAILED | ${new Date().toISOString()} | Error: ${error.message}`);
        }
      }
    }

    console.log('='.repeat(50));

    return res.status(200).json({
      success: true,
      message: `Booking ${status} successfully`,
      data: booking,
      ...(status === "accepted" && { otp: booking.otpStart })
    });

  } catch (err) {
    console.error("❌ UPDATE_STATUS_ERROR:", err.message);
    return res.status(500).json({ 
      success: false, 
      message: err.message 
    });
  }
};

/* ------------------------------------------------------------
   🏢 GET BOOKINGS BY VENDOR
------------------------------------------------------------ */
export const getBookingsByVendor = async (req, res) => {
  try {
    console.log('\n🏢 === GET VENDOR BOOKINGS ===');
    const { vendorId } = req.params;
    console.log(`🔍 Fetching bookings for vendor: ${vendorId}`);

    const bookings = await Booking.find({ vendorId: vendorId })
      .sort({ createdAt: -1 });

    // Enrich with customer details
    const enrichedBookings = await Promise.all(
      bookings.map(async (booking) => {
        const customer = await User.findOne({ user_id: booking.userId });
        
        return {
          ...booking.toObject(),
          customer: customer ? {
            id: customer.user_id,
            name: customer.name,
            phone: customer.phone
          } : null
        };
      })
    );

    console.log(`✅ Found ${bookings.length} bookings`);
    console.log('='.repeat(50));

    return res.status(200).json({
      success: true,
      count: bookings.length,
      data: enrichedBookings,
    });

  } catch (error) {
    console.error("❌ GET_VENDOR_BOOKINGS_ERROR:", error.message);
    return res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
};

/* ------------------------------------------------------------
   📜 BOOKING HISTORY (Filterable)
------------------------------------------------------------ */
export const getBookingHistory = async (req, res) => {
  try {
    console.log('\n📜 === GET BOOKING HISTORY ===');
    const userId = req.user.user_id; // Secure token-based ID
    const { status } = req.query;

    console.log(`🔍 User: ${userId} | Status Filter: ${status || 'all'}`);

    const filter = { userId: userId }; // Removed Number() as user_id might be string

    if (status) {
      filter.status = status;
    }

    const bookings = await Booking.find(filter).sort({ createdAt: -1 });

    // Enrich with vendor details
    const enrichedBookings = await Promise.all(
      bookings.map(async (booking) => {
        const vendorDetails = await getVendorDetails(booking.vendorId);
        return {
          ...booking.toObject(),
          vendor: vendorDetails
        };
      })
    );

    console.log(`✅ Found ${bookings.length} bookings`);
    console.log('='.repeat(50));

    return res.status(200).json({
      success: true,
      count: bookings.length,
      data: enrichedBookings,
    });

  } catch (err) {
    console.error("❌ GET_HISTORY_ERROR:", err.message);
    return res.status(500).json({ 
      success: false, 
      message: err.message 
    });
  }
};
