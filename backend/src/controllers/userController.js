import axios from "axios";
import crypto from "crypto";
import User from "../models/userModel.js";
import Plan from "../models/planModel.js";
import { sendNotification, sendOtpNotification } from "../utils/sendNotification.js";
import { generateToken } from "../middlewares/authMiddleware.js";

import asyncHandler from "../utils/asyncHandler.js";
import logger from "../utils/logger.js";

/**
 * Hash a numeric OTP using HMAC-SHA256 so it is never stored in plaintext.
 * Uses JWT_SECRET (already required at startup) as the HMAC key.
 */
const hashOtp = (otp) =>
  crypto.createHmac("sha256", process.env.JWT_SECRET).update(String(otp)).digest("hex");

/* ------------------------------------------------------------
   📲 REGISTER USER (Send OTP)
------------------------------------------------------------ */
export const registerUser = asyncHandler(async (req, res) => {
  const { phone, fcmToken } = req.body;
  
  // Generate secure random 4-digit OTP
  const otp = crypto.randomInt(1000, 10000);
  const otpExpiryTime = new Date(Date.now() + 5 * 60000); // 5 mins in future
  
  // +otp +otpExpiry +otpAttempts needed because those fields have select:false in the schema
  let user = await User.findOne({ phone }).select('+otp +otpExpiry +otpAttempts');

  const hashedOtp = hashOtp(otp);

  if (!user) {
    user = await User.create({ phone, fcmToken, otp: hashedOtp, otpExpiry: otpExpiryTime });
  } else {
    user.otp = hashedOtp;
    user.otpExpiry = otpExpiryTime;
    user.otpAttempts = 0; // Reset attempts on new OTP request
    if (fcmToken && fcmToken !== user.fcmToken) {
      user.fcmToken = fcmToken;
    }
    await user.save();
  }

  const maskedPhone = String(phone).replace(/(\d{2})\d+(\d{2})/, '$1****$2');
  logger.info(`✅ OTP_GENERATED | User: ${user.user_id} | Phone: ${maskedPhone}`);
  
  // Send push notification with OTP (Fail-safe)
  const tokenToUse = fcmToken || user.fcmToken;
  if (tokenToUse) {
    sendOtpNotification(tokenToUse, otp, user.user_id).catch(() => {});
  }

  return res.status(200).json({
    success: true,
    message: "OTP sent successfully",
    userId: user.user_id,
    isNewUser: !user.name && !user.gender,
  });
});

/* ------------------------------------------------------------
   🔍 VERIFY OTP
------------------------------------------------------------ */
export const verifyOtp = asyncHandler(async (req, res) => {
  const { phone, otp } = req.body;
  // +otp +otpExpiry +otpAttempts needed because those fields have select:false in the schema
  const user = await User.findOne({ phone }).select('+otp +otpExpiry +otpAttempts');

  if (!user) {
    res.status(404);
    throw new Error("User not found");
  }

  if (!user.otp || !user.otpExpiry) {
    res.status(400);
    throw new Error("OTP not requested or expired");
  }

  if (Date.now() > user.otpExpiry.getTime()) {
    user.otp = null;
    user.otpExpiry = null;
    user.otpAttempts = 0;
    await user.save();
    res.status(400);
    throw new Error("OTP expired");
  }

  if (user.otpAttempts >= 5) {
    res.status(429);
    throw new Error("Too many OTP attempts. Please request a new OTP.");
  }

  if (hashOtp(otp) !== user.otp) {
    user.otpAttempts += 1;
    await user.save();
    res.status(400);
    throw new Error("Invalid OTP");
  }

  // Clear OTP and login
  user.otp = null;
  user.otpExpiry = null;
  user.otpAttempts = 0;
  await user.save();

  const token = generateToken(String(user.user_id), user.tokenVersion);
  const isNewUser = !user.name && !user.gender;

  // Welcome notification (Non-blocking)
  if (user.fcmToken) {
    const title = isNewUser ? "✅ Verification Successful!" : "🎉 Welcome Back!";
    const body = isNewUser ? "Welcome! Please complete your profile." : `Hello ${user.name || 'User'}, you're successfully logged in.`;
    sendNotification(user.fcmToken, title, body, { type: isNewUser ? 'welcome' : 'login' }).catch(() => {});
  }

  return res.status(200).json({
    success: true,
    message: "OTP verified successfully",
    token,
    userId: user.user_id,
    isNewUser,
    user: {
      user_id: user.user_id,
      name: user.name,
      phone: user.phone,
      gender: user.gender
    }
  });
});

/* ------------------------------------------------------------
   ✏️ UPDATE USER PROFILE
------------------------------------------------------------ */
export const updateUserDetails = asyncHandler(async (req, res) => {
  const userId = req.user.user_id; // Secure from JWT
  const { name, gender } = req.body;
  
  const user = await User.findOne({ user_id: userId });
  if (!user) {
    res.status(404);
    throw new Error("User not found");
  }

  user.name = name || user.name;
  user.gender = gender || user.gender;
  await user.save();

  // Profile update notification
  if (user.fcmToken) {
    sendNotification(user.fcmToken, "✅ Profile Updated!", "Your profile details have been saved.", { type: "profile_update" }).catch(() => {});
  }

  return res.status(200).json({
    success: true,
    message: "Profile updated successfully",
    user: {
      user_id: user.user_id,
      name: user.name,
      phone: user.phone,
      gender: user.gender,
      address: user.address,
      location: user.location
    }
  });
});

/* ------------------------------------------------------------
   👤 GET USER PROFILE
------------------------------------------------------------ */
export const getUserProfile = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;
  const user = await User.findOne({ user_id: userId })
    .select("user_id name phone gender address location isOnline subscription createdAt");

  if (!user) {
    res.status(404);
    throw new Error("User not found");
  }

  return res.status(200).json({ success: true, data: user });
});

/**
 * Legacy support for direct profile update (PUT)
 */
export const updateUserProfile = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;
  // phone intentionally excluded — changing it requires OTP re-verification
  const { name, address } = req.body;

  const updatedUser = await User.findOneAndUpdate(
    { user_id: userId },
    { name, address },
    { new: true }
  ).select("user_id name phone gender address location isOnline subscription createdAt");

  if (!updatedUser) {
    res.status(404);
    throw new Error("User not found");
  }

  return res.status(200).json({ success: true, message: "Profile updated", data: updatedUser });
});

/* ------------------------------------------------------------
   📍 UPDATE LOCATION (With Geocoding)
------------------------------------------------------------ */
export const updateUserLocation = asyncHandler(async (req, res) => {
  const { latitude, longitude, address: providedAddress } = req.body;
  const userId = req.user.user_id;

  const user = await User.findOne({ user_id: userId });
  if (!user) {
    res.status(404);
    throw new Error("User not found");
  }

  let address = providedAddress || "Address not found";
  
  // Geocode if address not provided by client
  if (!providedAddress && latitude && longitude) {
    try {
      const apiKey = process.env.OPENCAGE_API_KEY;
      const geoUrl = `https://api.opencagedata.com/geocode/v1/json?q=${latitude},${longitude}&key=${apiKey}`;
      const response = await axios.get(geoUrl);
      if (response.data.results.length > 0) {
        address = response.data.results[0].formatted;
      }
    } catch {
      logger.warn("⚠️ Geocoding failed, using coordinates only.");
    }
  }

  user.location = { type: "Point", coordinates: [longitude, latitude] };
  user.address = address;
  user.isOnline = true;
  await user.save();

  // Location notification
  if (user.fcmToken) {
    sendNotification(user.fcmToken, "📍 Location Updated", `New location: ${address}`, { type: "location_update" }).catch(() => {});
  }

  return res.status(200).json({
    success: true,
    message: "Location updated successfully",
    user: {
      user_id: user.user_id,
      name: user.name,
      phone: user.phone,
      address: user.address,
      location: user.location
    },
    location: { latitude, longitude, address }
  });
});

/* ------------------------------------------------------------
   💳 SUBSCRIPTION PLANS
------------------------------------------------------------ */
export const createDefaultPlans = asyncHandler(async (req, res) => {
  const existing = await Plan.find();
  if (existing.length > 0) {
    return res.status(200).json({ success: true, message: "Plans already exist" });
  }

  await Plan.insertMany([
    { name: "Basic Plan", price: 199, duration: "1 month", features: ["Basic access", "Email support"] },
    { name: "Pro Plan", price: 499, duration: "3 months", features: ["Unlimited storage", "Priority support"] },
    { name: "Premium Plan", price: 999, duration: "1 year", features: ["24/7 support", "Custom features"] },
  ]);

  return res.status(201).json({ success: true, message: "Plans created successfully" });
});

export const getAllPlans = asyncHandler(async (req, res) => {
  const plans = await Plan.find();
  return res.status(200).json({ success: true, data: plans });
});

export const getPlansByType = asyncHandler(async (req, res) => {
  const { planType } = req.query;
  if (!planType) {
    res.status(400);
    throw new Error("planType query parameter is required");
  }

  const plans = await Plan.find({ planType });
  return res.status(200).json({ success: true, data: plans });
});

export const getPlanById = asyncHandler(async (req, res) => {
  const plan = await Plan.findById(req.params.id);
  if (!plan) {
    res.status(404);
    throw new Error("Plan not found");
  }
  return res.status(200).json({ success: true, data: plan });
});
