import mongoose from "mongoose";
import AutoIncrementFactory from "mongoose-sequence";

/** @type {any} */
const AutoIncrement = AutoIncrementFactory(/** @type {any} */(mongoose));

/* ------------------------------------------
   👨‍🔧 VENDOR SCHEMA
------------------------------------------- */
const vendorSchema = new mongoose.Schema(
  {
    phone: {
      type: Number,
      required: true,
      unique: true,
    },
    name: { type: String, trim: true, maxlength: 100 },
    email: {
      type: String,
      trim: true,
      lowercase: true,
      maxlength: 254,
      match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, "Invalid email address"],
    },

    // 🛠️ Services offered by vendor
    selectedServices: [
      {
        type: String,
        required: true,
        trim: true,
      }
    ],

    // 📍 GeoJSON Location
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: { type: [Number], default: [0, 0] }, // [longitude, latitude]
    },

    // 🆕 Address
    address: {
      type: String,
      trim: true,
      default: "",
    },

    // 🔔 Firebase Cloud Messaging Tokens (array for multiple devices)
    fcmTokens: {
      type: [String],
      default: [],
    },

    // ⭐ Rating
    rating: {
      type: Number,
      default: 0,
      min: 0,
      max: 5,
    },

    // 📊 Stats
    totalBookings: {
      type: Number,
      default: 0,
    },

    completedBookings: {
      type: Number,
      default: 0,
    },

    totalRating: {
      type: Number,
      default: 0,
    },

    // 🔗 Subscription reference
    subscription: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subscription",
      default: null,
    },
  },
  { timestamps: true }
);

// 🚀 DATABASE INDEXES
// Hot path: Matcher finds online vendors of a specific service.
vendorSchema.index({ selectedServices: 1, vendor_id: 1 }); 
// Note: Standalone location index is removed as geo-queries are done via VendorPresence.
vendorSchema.index({ rating: -1 });

// Auto-increment vendor_id
vendorSchema.plugin(AutoIncrement, {
  id: "vendor_seq",
  inc_field: "vendor_id",
});

/** @type {import('./types.js').VendorModel} */
const Vendor = /** @type {any} */ (mongoose.model("Vendor", vendorSchema));

export default Vendor;
