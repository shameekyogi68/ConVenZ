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
    const count = await triggerHourlyNudge();
    res.status(202).json({ 
      success: true, 
      message: "Manually triggered hourly nudge",
      usersReached: count
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

export default router;
