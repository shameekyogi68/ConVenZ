import express from "express";
import {
  createPlan,
  getActivePlans,
  purchaseSubscription,
  getUserSubscription,
} from "../controllers/subscriptionController.js";
import { protect } from "../middlewares/authMiddleware.js";

const router = express.Router();

/* ------------------------------------------
   💳 SUBSCRIPTION ROUTES
------------------------------------------- */

// Public: Get all active plans (supports ?planType=customer)
router.get("/plans", getActivePlans);

// Protected: Purchase a subscription (userId comes from JWT token)
router.post("/purchase", protect, purchaseSubscription);

// Protected: Get user's active subscription
router.get("/user/:userId", protect, getUserSubscription);
router.get("/my", protect, getUserSubscription); // Alias: get own subscription without userId in URL

// Admin: Create a plan (should add admin middleware in production)
router.post("/plans", createPlan);

export default router;
