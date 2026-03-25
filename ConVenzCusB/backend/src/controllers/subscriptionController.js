import Plan from "../models/planModel.js";
import Subscription from "../models/subscriptionModel.js";
import User from "../models/userModel.js";

// Helper to calculate expiry date
const calculateExpiry = (duration) => {
  const date = new Date();
  if (duration.includes("month")) {
    const months = parseInt(duration) || 1;
    date.setMonth(date.getMonth() + months);
  } else if (duration.includes("year")) {
    const years = parseInt(duration) || 1;
    date.setFullYear(date.getFullYear() + years);
  } else if (duration.includes("day")) {
      const days = parseInt(duration) || 1;
      date.setDate(date.getDate() + days);
  }
  return date;
};

/* ------------------------------------------------------------
   🛠 ADMIN: CREATE PLANS
------------------------------------------------------------ */
export const createPlan = async (req, res) => {
  try {
    const { name, price, duration, features } = req.body;
    const plan = await Plan.create({ name, price, duration, features });
    res.status(201).json({ success: true, message: "Plan created", data: plan });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/* ------------------------------------------------------------
   👤 USER: GET ALL ACTIVE PLANS
------------------------------------------------------------ */
export const getActivePlans = async (req, res) => {
  try {
    const plans = await Plan.find({ active: true });
    res.status(200).json({ success: true, data: plans });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/* ------------------------------------------------------------
   🎟 USER: PURCHASE SUBSCRIPTION
------------------------------------------------------------ */
export const purchaseSubscription = async (req, res) => {
  try {
    const { userId, planId } = req.body;

    // 1. Validate User & Plan
    const user = await User.findOne({ user_id: userId });
    if (!user) return res.status(404).json({ success: false, message: "User not found" });

    const plan = await Plan.findById(planId);
    if (!plan) return res.status(404).json({ success: false, message: "Plan not found" });

    // 2. Check if user already has an ACTIVE subscription
    const existingActiveSub = await Subscription.findOne({ 
      userId: userId, 
      status: "Active",
      expiryDate: { $gt: new Date() }
    });

    if (existingActiveSub) {
      return res.status(400).json({ 
        success: false, 
        message: `You already have an active ${existingActiveSub.currentPack} until ${existingActiveSub.expiryDate.toLocaleDateString()}. Please wait for it to expire before selecting another plan.`,
        data: existingActiveSub 
      });
    }

    // 3. If there's an expired subscription, mark it as Expired
    const expiredSub = await Subscription.findOne({ 
      userId: userId, 
      status: "Active",
      expiryDate: { $lte: new Date() }
    });

    if (expiredSub) {
      expiredSub.status = "Expired";
      await expiredSub.save();
    }

    // 4. Calculate Expiry
    const expiryDate = calculateExpiry(plan.duration);

    // 5. Create Subscription Entry
    const newSub = await Subscription.create({
      userId: userId,
      planId: plan._id,
      currentPack: plan.name,
      price: plan.price,
      expiryDate: expiryDate,
      status: "Active"
    });

    // 6. Link Subscription to User Profile
    user.subscription = newSub._id;
    await user.save();

    res.status(201).json({
      success: true,
      message: "Subscription activated successfully",
      data: newSub
    });

  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

/* ------------------------------------------------------------
   👤 GET USER'S CURRENT SUBSCRIPTION
------------------------------------------------------------ */
export const getUserSubscription = async (req, res) => {
  try {
    const { userId } = req.params;

    const sub = await Subscription.findOne({ userId, status: "Active" })
      .sort({ createdAt: -1 })
      .populate("planId");

    if (!sub) {
      return res.status(404).json({ success: false, message: "No active subscription found" });
    }

    res.status(200).json({ success: true, data: sub });

  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
