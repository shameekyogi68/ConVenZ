import express from "express";
import {
  createPlan,
  getActivePlans,
  purchaseSubscription,
  getUserSubscription
} from "../controllers/subscriptionController.js";
import { protect } from "../middlewares/authMiddleware.js";

const router = express.Router();

/* ------------------------------------------
   💳 SUBSCRIPTION ROUTES
------------------------------------------- */
router.post("/plans", createPlan);
router.get("/plans", getActivePlans);
router.post("/purchase", protect, purchaseSubscription);
router.get("/user/:userId", protect, getUserSubscription);

export default router;
