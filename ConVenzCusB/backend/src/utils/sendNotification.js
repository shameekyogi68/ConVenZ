import admin from "../config/firebase.js";

/**
 * Send push notification to a single device
 * @param {string} token - FCM device token
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Additional data payload (optional)
 * @returns {Promise<string>} - Message ID on success
 */
export const sendNotification = async (token, title, body, data = {}) => {
  try {
    // Convert all data values to strings as FCM requires
    const stringData = {};
    if (data && Object.keys(data).length > 0) {
      Object.keys(data).forEach(key => {
        stringData[key] = String(data[key]);
      });
    }
    stringData.clickAction = stringData.clickAction || "FLUTTER_NOTIFICATION_CLICK";

    const message = {
      token,
      notification: {
        title,
        body,
      },
      data: stringData,
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };
    
    const response = await admin.messaging().send(message);
    console.log(`✅ FCM_SENT | ${new Date().toISOString()} | MessageID: ${response}`);
    
    return response;
  } catch (error) {
    console.error(`❌ FCM_FAILED | ${new Date().toISOString()} | Error: ${error.message} | Code: ${error.code} | Token: ${token ? token.substring(0, 30) + '...' : 'NULL'}`);
    
    // Handle specific FCM errors
    if (error.code === 'messaging/registration-token-not-registered' || 
        error.code === 'messaging/invalid-registration-token') {
      console.error("🚫 Token invalid/expired - app needs to re-register");
      throw new Error(`Invalid or expired FCM token: ${error.message}`);
    } else if (error.code === 'messaging/invalid-argument') {
      console.error("🚫 Invalid payload - check data format");
      throw new Error(`Invalid FCM message format: ${error.message}`);
    } else if (error.message.includes('Requested entity was not found')) {
      console.error("🚫 FCM project mismatch or deleted app instance");
      throw new Error(`FCM entity not found: Token may be from wrong project or deleted app instance`);
    }
    
    throw error;
  }
};

/**
 * Send push notification to multiple devices
 * @param {string[]} tokens - Array of FCM device tokens
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Additional data payload (optional)
 * @returns {Promise<object>} - Batch response with success/failure counts
 */
export const sendMultipleNotifications = async (tokens, title, body, data = {}) => {
  try {
    // Convert all data values to strings as FCM requires
    const stringData = {};
    if (data && Object.keys(data).length > 0) {
      Object.keys(data).forEach(key => {
        stringData[key] = String(data[key]);
      });
    }
    stringData.clickAction = stringData.clickAction || "FLUTTER_NOTIFICATION_CLICK";

    const message = {
      notification: {
        title,
        body,
      },
      data: stringData,
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      tokens,
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`🔥 Sent to ${response.successCount}/${tokens.length} devices`);
    
    if (response.failureCount > 0) {
      console.log(`⚠️  Failed to send to ${response.failureCount} devices`);
      
      // Log details about failed tokens
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          console.error(`   ❌ Token ${idx + 1}: ${resp.error?.code} - ${resp.error?.message}`);
          if (resp.error?.code === 'messaging/registration-token-not-registered' ||
              resp.error?.code === 'messaging/invalid-registration-token') {
            console.error(`      🚫 Token ${tokens[idx].substring(0, 20)}... is invalid/expired`);
          }
        }
      });
    }

    return response;
  } catch (error) {
    console.error("❌ Failed to send multiple notifications:", error.message);
    console.error("⚠️  Error code:", error.code);
    throw error;
  }
};

/**
 * Send push notification to a topic
 * @param {string} topic - FCM topic name
 * @param {string} title - Notification title
 * @param {string} body - Notification body
 * @param {object} data - Additional data payload (optional)
 * @returns {Promise<string>} - Message ID on success
 */
export const sendTopicNotification = async (topic, title, body, data = {}) => {
  try {
    // Convert all data values to strings as FCM requires
    const stringData = {};
    if (data && Object.keys(data).length > 0) {
      Object.keys(data).forEach(key => {
        stringData[key] = String(data[key]);
      });
    }
    stringData.clickAction = stringData.clickAction || "FLUTTER_NOTIFICATION_CLICK";

    const message = {
      topic,
      notification: {
        title,
        body,
      },
      data: stringData,
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`🔥 Notification sent to topic "${topic}":`, response);
    return response;
  } catch (error) {
    console.error(`❌ Failed to send notification to topic "${topic}":`, error.message);
    console.error("⚠️  Error code:", error.code);
    throw error;
  }
};

/**
 * Send OTP notification to user
 * @param {string} phone - User's phone number
 * @param {number} otp - The OTP code
 * @param {string} fcmToken - User's FCM token
 * @returns {Promise<string>} - Message ID on success
 */
export const sendOtpNotification = async (fcmToken, otp, userId = null) => {
  if (!fcmToken) {
    console.log(`⚠️  OTP_NOTIFICATION_SKIPPED | ${new Date().toISOString()} | Reason: No FCM token`);
    return null;
  }

  try {
    const message = {
      token: fcmToken,
      notification: {
        title: "🔐 Your Login OTP",
        body: `Your OTP is ${otp}`,
      },
      data: {
        type: "otp",
        otp: String(otp),
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "otp_channel",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            alert: {
              title: "🔐 Your Login OTP",
              body: `Your OTP is ${otp}`,
            },
          },
        },
      },
    };
    
    const response = await admin.messaging().send(message);
    console.log(`📲 OTP_PUSH_SENT | ${new Date().toISOString()} | User: ${userId || 'N/A'} | OTP: ${otp}`);
    return response;
  } catch (error) {
    console.error(`❌ OTP_PUSH_FAILED | ${new Date().toISOString()} | User: ${userId || 'N/A'} | Error: ${error.message}`);
    
    // Handle specific FCM errors
    if (error.code === 'messaging/registration-token-not-registered' || 
        error.code === 'messaging/invalid-registration-token') {
      console.error("🚫 Token invalid/expired");
      throw new Error(`Invalid or expired FCM token: ${error.message}`);
    } else if (error.message.includes('Requested entity was not found')) {
      console.error("🚫 FCM project mismatch or deleted app instance");
      throw new Error(`FCM entity not found: ${error.message}`);
    }
    
    throw error;
  }
};

/**
 * Validate if an FCM token is valid by sending a test message (dry run)
 * @param {string} token - FCM device token to validate
 * @returns {Promise<boolean>} - True if valid, false if invalid
 */
export const validateFcmToken = async (token) => {
  try {
    const message = {
      token,
      notification: {
        title: "Test",
        body: "Validation",
      },
      data: {
        test: "true",
      },
    };

    // Use dryRun mode to validate without actually sending
    await admin.messaging().send(message, true);
    console.log("✅ FCM token is valid");
    return true;
  } catch (error) {
    if (error.code === 'messaging/registration-token-not-registered' || 
        error.code === 'messaging/invalid-registration-token' ||
        error.message.includes('Requested entity was not found')) {
      console.log("❌ FCM token is invalid or expired");
      return false;
    }
    // For other errors, assume token might be valid
    console.warn("⚠️  Could not validate token:", error.message);
    return true;
  }
};
