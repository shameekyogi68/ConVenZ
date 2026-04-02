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

// Test manual trigger for hourly nudge (Admin or Debug Only)
router.get("/test-hourly-nudge", async (req, res) => {
  try {
    const { triggerHourlyNudge } = await import("../utils/scheduler.js");
    console.log(`📡 [API] Manual nudge request received | ${new Date().toISOString()}`);
    const result = await triggerHourlyNudge();
    res.status(202).json({ 
      success: true, 
      message: "Manually triggered hourly nudge",
      stats: result
    });
  } catch (err) {
    console.error(`❌ [API] Manual nudge failed: ${err.message}`);
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
