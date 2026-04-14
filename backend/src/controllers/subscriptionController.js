import Plan from "../models/planModel.js";
import Subscription from "../models/subscriptionModel.js";
import User from "../models/userModel.js";
import asyncHandler from "../utils/asyncHandler.js";
import dayjs from "dayjs";


// ─────────────────────────────────────────────
// Helper: Calculate subscription expiry date
// ─────────────────────────────────────────────
export const calculateExpiry = (duration) => {
  const [valueStr, unit] = duration.split(" ");
  const value = parseInt(valueStr) || 1;
  const unitMapped = unit.toLowerCase().startsWith("year") ? "year" : unit.toLowerCase().startsWith("month") ? "month" : "day";
  
  // dayjs handles month-end overflows (e.g., Jan 31 + 1 month = Feb 28/29) automatically.
  return dayjs().add(value, unitMapped).toDate();
};


/* ------------------------------------------------------------
   🛠️ ADMIN: CREATE A PLAN
------------------------------------------------------------ */
export const createPlan = asyncHandler(async (req, res) => {
  const { name, price, duration, features, planType } = req.body;
  const plan = await Plan.create({ name, price, duration, features, planType: planType || "customer" });
  res.status(201).json({ success: true, message: "Plan created", data: plan });
});

/* ------------------------------------------------------------
   📋 GET ALL ACTIVE PLANS (supports ?planType=customer filter)
------------------------------------------------------------ */
export const getActivePlans = asyncHandler(async (req, res) => {
  const filter = { active: true };
  if (req.query.planType) filter.planType = req.query.planType;
  const plans = await Plan.find(filter).sort({ price: 1 });
  res.status(200).json({ success: true, count: plans.length, data: plans });
});

/* ------------------------------------------------------------
   🎟️ PURCHASE SUBSCRIPTION (Secure: userId from JWT token)
------------------------------------------------------------ */
export const purchaseSubscription = asyncHandler(async (req, res) => {
  // ✅ SECURITY FIX: Use userId from verified JWT token, not from request body
  const userId = req.user.user_id;
  const { planId } = req.body;

  if (!planId) {
    res.status(400);
    throw new Error("planId is required");
  }

  // 1. Validate Plan exists and is active
  const plan = await Plan.findById(planId);
  if (!plan || !plan.active) {
    res.status(404);
    throw new Error("Plan not found or is inactive");
  }

  // 2. Check if user already has an ACTIVE subscription
  const existingActiveSub = await Subscription.findOne({
    userId,
    status: "Active",
    expiryDate: { $gt: new Date() },
  });

  if (existingActiveSub) {
    res.status(400);
    throw new Error(
      `You already have an active "${existingActiveSub.currentPack}" plan until ${existingActiveSub.expiryDate.toLocaleDateString("en-IN")}. Please wait for it to expire.`
    );
  }

  // 3. Mark any expired subscriptions as Expired (cleanup)
  await Subscription.updateMany(
    { userId, status: "Active", expiryDate: { $lte: new Date() } },
    { $set: { status: "Expired" } }
  );

  // 4. Calculate expiry date
  const expiryDate = calculateExpiry(plan.duration);

  // 5. Create new subscription
  const newSub = await Subscription.create({
    userId,
    planId: plan._id,
    currentPack: plan.name,
    price: plan.price,
    expiryDate,
    status: "Active",
  });

  // 6. Link subscription reference to user profile
  await User.findOneAndUpdate({ user_id: userId }, { subscription: newSub._id });

  res.status(201).json({
    success: true,
    message: `"${plan.name}" subscription activated successfully!`,
    data: newSub,
  });
});

/* ------------------------------------------------------------
   👤 GET USER'S CURRENT ACTIVE SUBSCRIPTION
------------------------------------------------------------ */
export const getUserSubscription = asyncHandler(async (req, res) => {
  // ✅ SECURITY FIX: Never use param userId to prevent IDOR
  const userId = req.user.user_id;

  if (!userId) {
    res.status(400);
    throw new Error("userId is required");
  }

  // Auto-expire any subscriptions that are overdue
  await Subscription.updateMany(
    { userId, status: "Active", expiryDate: { $lte: new Date() } },
    { $set: { status: "Expired" } }
  );

  const sub = await Subscription.findOne({ userId, status: "Active" })
    .sort({ createdAt: -1 })
    .populate("planId", "name price duration features");

  if (!sub) {
    return res.status(404).json({ success: false, message: "No active subscription found" });
  }

  res.status(200).json({ success: true, data: sub });
});
