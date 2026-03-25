import User from "../models/userModel.js";
import { sendNotification, sendMultipleNotifications, sendTopicNotification } from "../utils/sendNotification.js";

/* ------------------------------------------------------------
   💾 UPDATE FCM TOKEN
------------------------------------------------------------ */
export const updateFcmToken = async (req, res) => {
  try {
    const { userId, fcmToken } = req.body;

    if (!userId || !fcmToken) {
      console.log(`❌ TOKEN_UPDATE_FAILED | ${new Date().toISOString()} | Reason: Missing userId or token`);
      return res.status(400).json({ 
        success: false, 
        message: "userId and fcmToken are required" 
      });
    }

    const user = await User.findOne({ user_id: userId });

    if (!user) {
      console.log(`❌ TOKEN_UPDATE_FAILED | ${new Date().toISOString()} | User: ${userId} | Reason: User not found`);
      return res.status(404).json({ 
        success: false, 
        message: "User not found" 
      });
    }

    // Check if token is already used by another user (prevent duplicates)
    const existingUser = await User.findOne({ fcmToken: fcmToken, user_id: { $ne: userId } });
    if (existingUser) {
      console.log(`🔄 TOKEN_MOVED | ${new Date().toISOString()} | From: ${existingUser.user_id} | To: ${userId}`);
      existingUser.fcmToken = null;
      await existingUser.save();
    }

    const isNew = !user.fcmToken;
    user.fcmToken = fcmToken;
    await user.save();

    console.log(`✅ TOKEN_UPDATED | ${new Date().toISOString()} | User: ${user.user_id} | Phone: ${user.phone} | Status: ${isNew ? 'NEW' : 'REFRESH'}`);

    return res.json({ 
      success: true, 
      message: "FCM token updated successfully" 
    });
  } catch (err) {
    console.error(`❌ TOKEN_UPDATE_ERROR | ${new Date().toISOString()} | Error: ${err.message}`);
    return res.status(500).json({ 
      success: false, 
      message: err.message 
    });
  }
};

/* ------------------------------------------------------------
   📤 SEND NOTIFICATION TO USER
------------------------------------------------------------ */
export const sendNotificationToUser = async (req, res) => {
  try {
    console.log('\n📤 === SEND NOTIFICATION TO USER ===');
    const { userId, title, body, data } = req.body;

    if (!userId || !title || !body) {
      console.log('❌ Missing required fields');
      return res.status(400).json({ 
        success: false, 
        message: "userId, title, and body are required" 
      });
    }

    // Get user's FCM token
    const user = await User.findOne({ user_id: userId });

    if (!user) {
      console.log(`❌ SEND_NOTIFICATION_FAILED | ${new Date().toISOString()} | User ${userId} not found`);
      return res.status(404).json({ 
        success: false, 
        message: "User not found" 
      });
    }

    if (!user.fcmToken) {
      console.log(`❌ NO_FCM_TOKEN | ${new Date().toISOString()} | User: ${userId}`);
      return res.status(400).json({ 
        success: false, 
        message: "User has no FCM token registered" 
      });
    }

    // Send notification using utility function
    try {
      const response = await sendNotification(user.fcmToken, title, body, data || {});
      console.log(`✅ MANUAL_NOTIFICATION_SENT | ${new Date().toISOString()} | User: ${userId} | MessageID: ${response}`);

      return res.json({ 
        success: true, 
        message: "Notification sent successfully",
        messageId: response
      });
    } catch (notificationError) {
      // If token is invalid/expired, remove it from database
      if (notificationError.message.includes('Invalid or expired FCM token') ||
          notificationError.message.includes('FCM entity not found')) {
        console.log(`🗑️  TOKEN_REMOVED | ${new Date().toISOString()} | User: ${userId} | Reason: Invalid/Expired`);
        user.fcmToken = null;
        await user.save();
        
        return res.status(400).json({
          success: false,
          message: "FCM token is invalid or expired. User needs to re-register for notifications.",
          tokenRemoved: true
        });
      }
      throw notificationError;
    }
  } catch (err) {
    console.error(`❌ SEND_NOTIFICATION_ERROR | ${new Date().toISOString()} | User: ${userId} | Error: ${err.message}`);
    return res.status(500).json({ 
      success: false, 
      message: err.message 
    });
  }
};

/* ------------------------------------------------------------
   📤 SEND NOTIFICATION TO MULTIPLE USERS
------------------------------------------------------------ */
export const sendNotificationToMultipleUsers = async (req, res) => {
  try {
    console.log('\n📤 === SEND NOTIFICATION TO MULTIPLE USERS ===');
    const { userIds, title, body, data } = req.body;

    if (!userIds || !Array.isArray(userIds) || !title || !body) {
      console.log('❌ Missing required fields or invalid userIds array');
      return res.status(400).json({ 
        success: false, 
        message: "userIds (array), title, and body are required" 
      });
    }

    console.log('👥 Target User IDs:', userIds);
    console.log('📨 Title:', title);
    console.log('📝 Body:', body);

    // Get all users' FCM tokens
    const users = await User.find({ 
      user_id: { $in: userIds },
      fcmToken: { $ne: null }
    });

    if (users.length === 0) {
      console.log('❌ No users found with FCM tokens');
      return res.status(404).json({ 
        success: false, 
        message: "No users found with FCM tokens" 
      });
    }

    console.log(`✅ Found ${users.length} users with FCM tokens`);

    const tokens = users.map(user => user.fcmToken);

    // Send notifications using utility function
    const response = await sendMultipleNotifications(tokens, title, body, data || {});
    
    console.log('✅ Notifications sent');
    console.log(`📊 Success: ${response.successCount}, Failed: ${response.failureCount}`);
    
    // Clean up invalid tokens from database
    if (response.failureCount > 0) {
      const invalidTokenIndexes = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && 
            (resp.error?.code === 'messaging/registration-token-not-registered' ||
             resp.error?.code === 'messaging/invalid-registration-token')) {
          invalidTokenIndexes.push(idx);
        }
      });
      
      if (invalidTokenIndexes.length > 0) {
        console.log(`🗑️  Removing ${invalidTokenIndexes.length} invalid tokens from database`);
        const invalidUserIds = invalidTokenIndexes.map(idx => users[idx].user_id);
        await User.updateMany(
          { user_id: { $in: invalidUserIds } },
          { $set: { fcmToken: null } }
        );
        console.log('✅ Invalid tokens removed');
      }
    }
    
    console.log('='.repeat(50));

    return res.json({ 
      success: true, 
      message: "Notifications sent",
      successCount: response.successCount,
      failureCount: response.failureCount,
      invalidTokensRemoved: response.failureCount
    });
  } catch (err) {
    console.error('❌ Send Multiple Notifications Error:', err.message);
    return res.status(500).json({ 
      success: false, 
      message: err.message 
    });
  }
};

/* ------------------------------------------------------------
   📤 SEND NOTIFICATION TO TOPIC
------------------------------------------------------------ */
export const sendNotificationToTopic = async (req, res) => {
  try {
    console.log('\n📤 === SEND NOTIFICATION TO TOPIC ===');
    const { topic, title, body, data } = req.body;

    if (!topic || !title || !body) {
      console.log('❌ Missing required fields');
      return res.status(400).json({ 
        success: false, 
        message: "topic, title, and body are required" 
      });
    }

    console.log('📢 Topic:', topic);
    console.log('📨 Title:', title);
    console.log('📝 Body:', body);

    // Send notification using utility function
    const response = await sendTopicNotification(topic, title, body, data || {});
    
    console.log('✅ Topic notification sent successfully');
    console.log('📬 Message ID:', response);
    console.log('='.repeat(50));

    return res.json({ 
      success: true, 
      message: "Topic notification sent successfully",
      messageId: response
    });
  } catch (err) {
    console.error('❌ Send Topic Notification Error:', err.message);
    return res.status(500).json({ 
      success: false, 
      message: err.message 
    });
  }
};
