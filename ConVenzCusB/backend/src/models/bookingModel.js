import mongoose from "mongoose";
import AutoIncrementFactory from "mongoose-sequence";

const AutoIncrement = AutoIncrementFactory(mongoose);

/* ------------------------------------------
   📅 BOOKING SCHEMA
------------------------------------------- */
const bookingSchema = new mongoose.Schema(
  {
    // Customer who created the booking
    userId: {
      type: Number,
      required: true,
      ref: "User"
    },

    // Vendor assigned to the booking
    vendorId: {
      type: Number,
      default: null,
      ref: "Vendor"
    },

    // Service requested
    selectedService: {
      type: String,
      required: true,
    },

    // Job description/details
    jobDescription: {
      type: String,
      required: true,
    },

    // Scheduled date
    date: {
      type: String,
      required: true,
    },

    // Scheduled time
    time: {
      type: String,
      required: true,
    },

    // Booking location
    location: {
      type: { type: String, default: "Point" },
      coordinates: { type: [Number], required: true }, // [longitude, latitude]
      address: { type: String, required: true },
    },

    // Booking status
    status: {
      type: String,
      enum: ["pending", "accepted", "rejected", "enroute", "completed", "cancelled"],
      default: "pending",
    },

    // OTP for verification (null until vendor accepts)
    otpStart: {
      type: Number,
      default: null,
    },

    // Distance from vendor to customer (in km)
    distance: {
      type: Number,
      default: null,
    },

    // External vendor details (from callback)
    externalVendor: {
      vendorId: String,
      vendorName: String,
      vendorPhone: String,
      vendorAddress: String,
      serviceType: String,
      assignedAt: Date,
      lastUpdated: Date,
    },
  },
  { timestamps: true }
);

// 🚀 ELITE DATABASE ARCHITECTURE INDEXES
bookingSchema.index({ userId: 1, status: 1 }); // Essential for "My Bookings" dashboard performance
bookingSchema.index({ vendorId: 1, status: 1 }); // Essential for Vendor's "My Jobs" performance
bookingSchema.index({ booking_id: 1 }); // Fast ID-based lookup
bookingSchema.index({ location: "2dsphere" }); // High-performance Nearby Search

// Auto-increment booking_id
bookingSchema.plugin(AutoIncrement, {
  id: "booking_seq",
  inc_field: "booking_id",
});

const Booking = mongoose.model("Booking", bookingSchema);

export default Booking;
