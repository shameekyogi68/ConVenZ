import express from "express";
import {
  createPlan,
  getActivePlans,
  purchaseSubscription,
  getUserSubscription,
} from "../controllers/subscriptionController.js";
import { protect } from "../middlewares/authMiddleware.js";
import { validate, subscriptionSchemas } from "../middlewares/validateMiddleware.js";


const router = express.Router();

// Admin-only middleware (matches pattern in userRoutes)
const adminProtect = (req, res, next) => {
  if (!process.env.ADMIN_SECRET) {
    return res.status(500).json({ success: false, message: "Server misconfiguration: ADMIN_SECRET not set" });
  }
  if (req.headers['x-admin-secret'] === process.env.ADMIN_SECRET) {
    return next();
  }
  return res.status(401).json({ success: false, message: "Unauthorized: Admin access required" });
};


/* ------------------------------------------
   💳 SUBSCRIPTION ROUTES
------------------------------------------- */


// Public: Get all active plans (supports ?planType=customer)
router.get("/plans", getActivePlans);

// Protected: Purchase a subscription (userId comes from JWT token)
router.post("/purchase", protect, validate(subscriptionSchemas.purchase), purchaseSubscription);


// Protected: Get user's active subscription
router.get("/user/:userId", protect, getUserSubscription);
router.get("/my", protect, getUserSubscription);

// Admin: Create a plan
router.post("/plans", adminProtect, validate(subscriptionSchemas.createPlan), createPlan);


export default router;
