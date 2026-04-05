import User from "../models/userModel.js";
import { sendNotification, sendMultipleNotifications, sendTopicNotification } from "../utils/sendNotification.js";
import asyncHandler from "../utils/asyncHandler.js";

/* ------------------------------------------------------------
   💾 UPDATE FCM TOKEN
   userId resolved from JWT — body userId ignored for security
------------------------------------------------------------ */
export const updateFcmToken = asyncHandler(async (req, res) => {
  const userId = req.user.user_id;
  const { fcmToken } = req.body;

  const user = await User.findOne({ user_id: userId });
  if (!user) {
    res.status(404);
    throw new Error("User not found");
  }

  // Clear token from any other user (same device, different account)
  await User.updateMany(
    { fcmToken, user_id: { $ne: userId } },
    { $set: { fcmToken: "" } }
  );

  user.fcmToken = fcmToken;
  await user.save();

  console.log(`✅ TOKEN_UPDATED | User: ${user.user_id} | Status: ${user.fcmToken ? 'REFRESH' : 'NEW'}`);

  return res.status(200).json({ success: true, message: "FCM token updated successfully" });
});

/* ------------------------------------------------------------
   📤 SEND NOTIFICATION TO SINGLE USER (Admin / Internal)
------------------------------------------------------------ */
export const sendNotificationToUser = asyncHandler(async (req, res) => {
  const { userId, title, body, data } = req.body;

  if (!userId || !title || !body) {
    res.status(400);
    throw new Error("userId, title, and body are required");
  }

  const user = await User.findOne({ user_id: userId });
  if (!user) {
    res.status(404);
    throw new Error("User not found");
  }

  if (!user.fcmToken) {
    res.status(400);
    throw new Error("User has no FCM token registered");
  }

  try {
    const messageId = await sendNotification(user.fcmToken, title, body, data || {});
    return res.status(200).json({ success: true, message: "Notification sent successfully", messageId });
  } catch (notificationError) {
    if (
      notificationError.message.includes('Invalid or expired FCM token') ||
      notificationError.message.includes('FCM entity not found')
    ) {
      user.fcmToken = null;
      await user.save();
      res.status(400);
      throw new Error("FCM token is invalid or expired. User needs to re-register for notifications.");
    }
    throw notificationError;
  }
});

/* ------------------------------------------------------------
   📤 SEND NOTIFICATION TO MULTIPLE USERS (Admin / Internal)
------------------------------------------------------------ */
export const sendNotificationToMultipleUsers = asyncHandler(async (req, res) => {
  const { userIds, title, body, data } = req.body;

  if (!userIds || !Array.isArray(userIds) || !title || !body) {
    res.status(400);
    throw new Error("userIds (array), title, and body are required");
  }

  const users = await User.find({
    user_id: { $in: userIds },
    fcmToken: { $nin: [null, ""] },
  });

  if (users.length === 0) {
    res.status(404);
    throw new Error("No users found with registered FCM tokens");
  }

  const tokens = users.map((u) => u.fcmToken);
  const response = await sendMultipleNotifications(tokens, title, body, data || {});

  // Clean up invalid tokens
  if (response.failureCount > 0) {
    const invalidIds = response.responses
      .map((r, i) => (!r.success ? users[i]?.user_id : null))
      .filter(Boolean);

    if (invalidIds.length > 0) {
      await User.updateMany({ user_id: { $in: invalidIds } }, { $set: { fcmToken: null } });
    }
  }

  return res.status(200).json({
    success: true,
    message: "Notifications dispatched",
    successCount: response.successCount,
    failureCount: response.failureCount,
  });
});

/* ------------------------------------------------------------
   📤 SEND NOTIFICATION TO TOPIC (Admin / Internal)
------------------------------------------------------------ */
export const sendNotificationToTopic = asyncHandler(async (req, res) => {
  const { topic, title, body, data } = req.body;

  if (!topic || !title || !body) {
    res.status(400);
    throw new Error("topic, title, and body are required");
  }

  const messageId = await sendTopicNotification(topic, title, body, data || {});

  return res.status(200).json({
    success: true,
    message: "Topic notification sent successfully",
    messageId,
  });
});
