import express from "express";
import {
  updateFcmToken,
  sendNotificationToUser,
  sendNotificationToMultipleUsers,
  sendNotificationToTopic
} from "../controllers/notificationController.js";

const router = express.Router();

/* ------------------------------------------
   🔔 NOTIFICATION ROUTES
------------------------------------------- */

// Update FCM token for a user
router.post("/update-token", updateFcmToken);

// Send notification to a single user
router.post("/send", sendNotificationToUser);

// Send notification to multiple users
router.post("/send-multiple", sendNotificationToMultipleUsers);

// Send notification to a topic
router.post("/send-topic", sendNotificationToTopic);

// Test manual trigger for hourly nudge (Admin or External Cron Only)
router.get("/test-hourly-nudge", async (req, res) => {
  try {
    // 🛡️ Security Check (Optional but recommended for production)
    // You can set CRON_SECRET in your Render environment variables
    const secret = req.query.secret || req.headers['x-cron-secret'];
    if (process.env.CRON_SECRET && secret !== process.env.CRON_SECRET) {
      console.warn(`🛡️ [API] Unauthorized nudge attempt blocked | IP: ${req.ip}`);
      return res.status(401).json({ success: false, message: "Unauthorized credentials" });
    }

    const { triggerHourlyNudge } = await import("../utils/scheduler.js");
    console.log(`📡 [API] External nudge request received | Source: ${req.get('User-Agent')}`);
    const result = await triggerHourlyNudge(true); // Pass true to bypass 45-min lock
    
    res.status(202).json({ 
      success: true, 
      message: "External trigger successful",
      stats: result
    });
  } catch (err) {
    console.error(`❌ [API] External nudge failed: ${err.message}`);
    res.status(500).json({ success: false, message: err.message });
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
