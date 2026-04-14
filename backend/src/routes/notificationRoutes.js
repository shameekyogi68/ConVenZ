import express from "express";
import {
  updateFcmToken,
  sendNotificationToUser,
  sendNotificationToMultipleUsers,
  sendNotificationToTopic
} from "../controllers/notificationController.js";

const router = express.Router();

// 🔒 ADMIN AUTH MIDDLEWARE
const adminProtect = (req, res, next) => {
  const adminSecret = req.headers['x-admin-secret'];
  if (!process.env.ADMIN_SECRET) {
    return res.status(500).json({ success: false, message: "Server misconfiguration: ADMIN_SECRET not set" });
  }
  if (adminSecret === process.env.ADMIN_SECRET) {
    next();
  } else {
    res.status(401).json({ success: false, message: "Unauthorized: Admin access required" });
  }
};

/* ------------------------------------------
   🔔 NOTIFICATION ROUTES
------------------------------------------- */

// Update FCM token for a user
router.post("/update-token", updateFcmToken);

// Send notification to a single user
router.post("/send", adminProtect, sendNotificationToUser);

// Send notification to multiple users
router.post("/send-multiple", adminProtect, sendNotificationToMultipleUsers);

// Send notification to a topic
router.post("/send-topic", adminProtect, sendNotificationToTopic);

// Manual trigger for hourly nudge (CRON_SECRET required in production)
router.get("/test-hourly-nudge", async (req, res) => {
  try {
    const secret = req.query.secret || req.headers['x-cron-secret'];
    if (process.env.CRON_SECRET && secret !== process.env.CRON_SECRET) {
      console.warn(`🛡️ [API] Unauthorized nudge attempt | IP: ${req.ip}`);
      return res.status(401).json({ success: false, message: "Unauthorized credentials" });
    }

    const { triggerHourlyNudge } = await import("../utils/scheduler.js");
    const result = await triggerHourlyNudge(true);

    return res.status(202).json({ success: true, message: "Nudge triggered", stats: result });
  } catch (err) {
    console.error(`❌ [API] External nudge failed: ${err.message}`);
    return res.status(500).json({ success: false, message: "Failed to trigger nudge" });
  }
});

// Get scheduler status
router.get("/scheduler-status", (req, res) => {
  res.json({
    success: true,
    timezone: "System/Asia-Kolkata (via node-cron)",
    schedule: "0 * * * * (Every Hour)",
    nextScheduledRuns: "Top of every hour",
    serverTime: new Date().toISOString()
  });
});

export default router;
