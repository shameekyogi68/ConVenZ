import mongoose from "mongoose";
import AutoIncrementFactory from "mongoose-sequence";

const AutoIncrement = AutoIncrementFactory(mongoose);

/* ------------------------------------------
   👤 USER SCHEMA
------------------------------------------- */
const userSchema = new mongoose.Schema(
  {
    phone: {
      type: Number,
      required: true,
      unique: true,
    },
    name: String,
    gender: { type: String, enum: ["Male", "Female", "Other"] },

    // 📍 GeoJSON Location
    location: {
      type: { type: String, default: "Point" },
      coordinates: { type: [Number], default: [0, 0] }, // [longitude, latitude]
    },

    // 🆕 Address (Reverse Geocoded)
    address: {
      type: String,
      default: "",
    },

    isOnline: { type: Boolean, default: false },

    // 🔗 Subscription reference (Links to the active subscription)
    subscription: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subscription",
      default: null,
    },

    // 🔔 Firebase Cloud Messaging Token
    fcmToken: {
      type: String,
      default: null,
    },

    // 🚫 Block Status (Admin Control)
    isBlocked: {
      type: Boolean,
      default: false,
    },

    // 📝 Block Reason (Optional)
    blockReason: {
      type: String,
      default: null,
    },

    // 📅 Blocked At (Timestamp)
    blockedAt: {
      type: Date,
      default: null,
    },

    // 🔑 OTP Storage (Scale-Proof)
    otp: {
      type: Number,
      default: null,
      index: true // Faster lookup for OTP verification
    },
    otpExpiry: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

// 🚀 DATABASE INDEXES
// Note: phone index is declared inline on the field above (index: true)
userSchema.index({ fcmToken: 1 });           // Faster push token lookup
userSchema.index({ location: "2dsphere" });  // High-performance geospatial search

// Auto-increment user_id ONLY for Users
userSchema.plugin(AutoIncrement, {
  id: "user_seq",
  inc_field: "user_id",
});

const User = mongoose.model("User", userSchema);
export default User;
