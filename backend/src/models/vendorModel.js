import mongoose from "mongoose";
import AutoIncrementFactory from "mongoose-sequence";

const AutoIncrement = AutoIncrementFactory(mongoose);

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
// Compound index covers both service filtering AND geospatial lookup — the core matching query.
// The standalone { location: "2dsphere" } index is intentionally omitted: MongoDB already
// uses the compound index for geo-only queries, and a duplicate 2dsphere index wastes space.
vendorSchema.index({ selectedServices: 1, location: "2dsphere" });
vendorSchema.index({ vendor_id: 1 });
vendorSchema.index({ rating: -1 });

// Auto-increment vendor_id
vendorSchema.plugin(AutoIncrement, {
  id: "vendor_seq",
  inc_field: "vendor_id",
});

const Vendor = mongoose.model("Vendor", vendorSchema);
export default Vendor;
