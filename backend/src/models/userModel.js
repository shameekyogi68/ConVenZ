import mongoose from "mongoose";
import AutoIncrementFactory from "mongoose-sequence";

/** @type {any} */
const AutoIncrement = AutoIncrementFactory(/** @type {any} */(mongoose));

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
    name: { type: String, trim: true, maxlength: 100 },
    gender: { type: String, enum: ["Male", "Female", "Other"] },

    // 📍 GeoJSON Location
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: { type: [Number], default: [0, 0] }, // [longitude, latitude]
    },

    // 🆕 Address (Reverse Geocoded)
    address: {
      type: String,
      trim: true,
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
      trim: true,
      maxlength: 500,
      default: null,
    },

    // 📅 Blocked At (Timestamp)
    blockedAt: {
      type: Date,
      default: null,
    },

    tokenVersion: {
      type: Number,
      default: 0,
    },

    // 🔑 OTP Storage — stored as HMAC-SHA256 hash, never plaintext
    otp: {
      type: String,
      default: null,
      select: false,
    },
    otpExpiry: {
      type: Date,
      default: null,
      select: false,
    },
    otpAttempts: {
      type: Number,
      default: 0,
      select: false,
    },
  },
  { timestamps: true }
);

// 🚀 DATABASE INDEXES
// Note: phone index is declared inline on the field above (index: true)
userSchema.index({ fcmToken: 1 }, { sparse: true });           // Sparse index: only indexes users with tokens, ignores nulls.
userSchema.index({ isBlocked: 1, fcmToken: 1 });          // Optimized index for scheduler marketing pushes.
userSchema.index({ location: "2dsphere" });  // High-performance geospatial search

// Auto-increment user_id ONLY for Users
userSchema.plugin(AutoIncrement, {
  id: "user_seq",
  inc_field: "user_id",
});

/** @type {import('./types.js').UserModel} */
const User = /** @type {any} */ (mongoose.model("User", userSchema));

export default User;
