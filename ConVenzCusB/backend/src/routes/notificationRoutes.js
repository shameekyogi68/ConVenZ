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

export default router;
