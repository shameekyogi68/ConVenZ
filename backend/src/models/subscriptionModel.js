import mongoose from "mongoose";

const subscriptionSchema = new mongoose.Schema(
  {
    userId: {
      type: Number,
      required: true,
      ref: "User" // Links to the User's numeric user_id
    },
    planId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Plan", // Links to planModel.js
      required: true
    },
    currentPack: { type: String, required: true, trim: true, maxlength: 100 },
    price: { type: Number, required: true, min: 0 },

    startDate: { type: Date, default: Date.now, immutable: true },
    expiryDate: { type: Date, required: true },

    status: {
      type: String,
      enum: ["Active", "Expired", "Cancelled"],
      default: "Active",
    },
  },
  { timestamps: true }
);

// 🚀 ELITE DATABASE ARCHITECTURE INDEXES
subscriptionSchema.index({ userId: 1, status: 1, expiryDate: 1 }); // Ultra-fast lookup for active user subscriptions with date filter
subscriptionSchema.index(
  { userId: 1, status: 1 },
  { unique: true, partialFilterExpression: { status: "Active" } }
); // DB-level enforcement: a user can only have ONE "Active" subscription at any time.
subscriptionSchema.index({ expiryDate: 1 }); // Standalone index for global expiry cleanup jobs

/** @type {import('./types.js').SubscriptionModel} */
const Subscription = /** @type {any} */ (mongoose.model("Subscription", subscriptionSchema));

export default Subscription;
