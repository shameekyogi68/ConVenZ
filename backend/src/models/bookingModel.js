import mongoose from "mongoose";
import AutoIncrementFactory from "mongoose-sequence";

/** @type {any} */
const AutoIncrement = AutoIncrementFactory(/** @type {any} */(mongoose));

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
      trim: true,
      maxlength: 100,
    },

    // Job description/details
    jobDescription: {
      type: String,
      required: true,
      trim: true,
      maxlength: 2000,
    },

    // Scheduled date
    date: {
      type: String,
      required: true,
      trim: true,
      match: [/^\d{4}-\d{2}-\d{2}$/, 'Please fill a valid YYYY-MM-DD date']
    },

    // Scheduled time
    time: {
      type: String,
      required: true,
      trim: true,
      match: [/^\d{2}:\d{2}(:\d{2})?$/, 'Please fill a valid HH:MM or HH:MM:SS time']
    },

    // Booking location
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: {
        type: [Number],
        required: true,
        validate: {
          validator: (coords) => {
            if (!Array.isArray(coords) || coords.length !== 2) {
              return false;
            }
            const [lng, lat] = coords;
            return lng >= -180 && lng <= 180 && lat >= -90 && lat <= 90;
          },
          message: "Location coordinates must be [longitude, latitude] within valid range",
        },
      }, // [longitude, latitude]
      address: { type: String, required: true, trim: true, maxlength: 500 },
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
      select: false,
    },

    // Distance from vendor to customer (in km)
    distance: {
      type: Number,
      default: null,
      min: 0,
    },

    // Reason provided by vendor when rejecting a booking
    rejectionReason: {
      type: String,
      trim: true,
      maxlength: 500,
      default: null,
    },

    // Customer's review
    rating: {
      type: Number,
      min: 1,
      max: 5,
      default: null,
    },
    review: {
      type: String,
      trim: true,
      maxlength: 1000,
      default: null,
    },

    // External vendor details (from callback)
    externalVendor: {
      vendorId: { type: String, trim: true },
      vendorName: { type: String, trim: true },
      vendorPhone: { type: String, trim: true },
      vendorAddress: { type: String, trim: true },
      serviceType: { type: String, trim: true },
      assignedAt: Date,
      lastUpdated: Date,
    }
  },
  { timestamps: true, optimisticConcurrency: true }
);

// 🚀 ELITE DATABASE ARCHITECTURE INDEXES
bookingSchema.index({ userId: 1, status: 1 }); // Essential for "My Bookings" dashboard performance
bookingSchema.index({ vendorId: 1, status: 1 }); // Essential for Vendor's "My Jobs" performance
bookingSchema.index({ booking_id: 1 }, { unique: true }); // Fast ID-based lookup with DB-level uniqueness enforcement
bookingSchema.index({ userId: 1, createdAt: -1 }); // Optimized for recent booking history queries
bookingSchema.index({ userId: 1, status: 1, createdAt: -1 }); // Optimized for active-booking lookup + recency

// 🛡️ Data Archival (MongoDB Partial TTL Index)
// Deletes completed or cancelled bookings exactly 1 year (31536000 seconds) after their last update
bookingSchema.index(
  { updatedAt: 1 }, 
  { expireAfterSeconds: 31536000, partialFilterExpression: { status: { $in: ["completed", "cancelled"] } } }
);

// Auto-increment booking_id
bookingSchema.plugin(AutoIncrement, {
  id: "booking_seq",
  inc_field: "booking_id",
});

// Keep status-related fields consistent at DB layer.
bookingSchema.pre("save", function normalizeBookingFields(next) {
  if (this.status !== "rejected") {
    this.rejectionReason = null;
  }
  if (this.status === "rejected" && !this.rejectionReason) {
    this.rejectionReason = "Rejected by vendor";
  }
  next();
});

/** @type {import('./types.js').BookingModel} */
const Booking = /** @type {any} */ (mongoose.model("Booking", bookingSchema));

export default Booking;
