import mongoose from "mongoose";

const planSchema = new mongoose.Schema({
  name: { type: String, required: true },
  price: { type: Number, required: true },
  duration: { type: String, required: true }, // e.g., "1 month", "3 months", "1 year"
  features: [{ type: String }],
  planType: { type: String, enum: ["customer", "vendor", "admin"], default: "customer" },
  active: { type: Boolean, default: true },
}, { timestamps: true });

// 🚀 ELITE DATABASE ARCHITECTURE INDEXES
planSchema.index({ planType: 1, active: 1 }); // Extremely fast lookup when grouping plans on the frontend

export default mongoose.model("Plan", planSchema);
