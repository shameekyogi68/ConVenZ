import mongoose from "mongoose";

const planSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, maxlength: 100 },
  price: { type: Number, required: true, min: 0 },
  duration: { type: String, required: true, trim: true, maxlength: 50 }, // e.g., "1 month", "3 months", "1 year"
  features: [{ type: String, trim: true }],
  planType: { type: String, enum: ["customer", "vendor", "admin"], default: "customer" },
  active: { type: Boolean, default: true },
}, { timestamps: true });

// 🚀 ELITE DATABASE ARCHITECTURE INDEXES
planSchema.index({ planType: 1, active: 1 }); // Extremely fast lookup when grouping plans on the frontend

/** @typedef {import('./types.js').PlanModel} PlanModel */
/** @type {PlanModel} */
const Plan = /** @type {any} */ (mongoose.model("Plan", planSchema));



export default Plan;
