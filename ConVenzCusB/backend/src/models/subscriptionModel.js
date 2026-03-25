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
    currentPack: { type: String, required: true },
    price: { type: Number, required: true },

    startDate: { type: Date, default: Date.now },
    expiryDate: { type: Date, required: true },

    status: {
      type: String,
      enum: ["Active", "Expired", "Cancelled"],
      default: "Active",
    },
  },
  { timestamps: true }
);

const Subscription = mongoose.model("Subscription", subscriptionSchema);
export default Subscription;
