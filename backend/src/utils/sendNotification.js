import admin from "../config/firebase.js";
import User from "../models/userModel.js";

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

/** 
 * FCM requires every data value to be a string.
 * @param {Record<string, any>} data
 * @returns {Record<string, string>}
 */
const stringifyData = (data = {}) => {
  /** @type {Record<string, string>} */
  const out = { clickAction: "FLUTTER_NOTIFICATION_CLICK" };
  for (const [k, v] of Object.entries(data)) {
    out[k] = String(v);
  }
  return out;
};

/** Android / APNs config shared by every message type. */
const platformConfig = (channelId = "high_importance_channel") => ({
  android: {
    /** @type {"high" | "normal"} */
    priority: "high",
    notification: { sound: "default", channelId },
  },
  apns: {
    payload: { aps: { sound: "default", badge: 1 } },
  },
});

/** Returns true for FCM error codes that mean the token is permanently invalid. */
const isInvalidTokenError = (code, message = "") =>
  code === "messaging/registration-token-not-registered" ||
  code === "messaging/invalid-registration-token" ||
  message.includes("Requested entity was not found");

// ─────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────

/**
 * Send a push notification to a single FCM device token.
 * Throws on FCM error so callers can handle invalid-token cleanup.
 */
export const sendNotification = async (token, title, body, data = {}) => {
  const message = {
    token,
    notification: { title, body },
    data: stringifyData(data),
    ...platformConfig(),
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`✅ FCM_SENT | ${new Date().toISOString()} | ID: ${response}`);
    return response;
  } catch (error) {
    console.error(`❌ FCM_FAILED | ${error.code} | ${error.message} | Token: ${token?.substring(0, 20)}…`);
    if (isInvalidTokenError(error.code, error.message)) {
      const e = new Error(`Invalid or expired FCM token: ${error.message}`);
      e.cause = error;
      throw e;
    }
    throw error;
  }
};

/**
 * Send a push notification to multiple FCM device tokens (multicast).
 * Automatically removes permanently invalid tokens from the User collection.
 */
export const sendMultipleNotifications = async (tokens, title, body, data = {}) => {
  if (!tokens?.length) return { successCount: 0, failureCount: 0, responses: [] };

  const message = {
    notification: { title, body },
    data: stringifyData(data),
    tokens,
    ...platformConfig(),
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`🔥 FCM_MULTICAST | ${response.successCount}/${tokens.length} delivered`);

    if (response.failureCount > 0) {
      const staleTokens = response.responses
        .map((r, i) => (!r.success && isInvalidTokenError(r.error?.code, r.error?.message)) ? tokens[i] : null)
        .filter(Boolean);

      if (staleTokens.length > 0) {
        try {
          const result = await User.updateMany(
            { fcmToken: { $in: staleTokens } },
            { $set: { fcmToken: "" } }
          );
          console.log(`🧹 FCM_CLEANUP | Removed ${result.modifiedCount} stale token(s)`);
        } catch (cleanupErr) {
          console.error(`❌ FCM_CLEANUP_FAILED | ${cleanupErr.message}`);
        }
      }
    }

    return response;
  } catch (error) {
    console.error(`❌ FCM_MULTICAST_FAILED | ${error.message}`);
    throw error;
  }
};

/**
 * Send a push notification to an FCM topic.
 */
export const sendTopicNotification = async (topic, title, body, data = {}) => {
  const message = {
    topic,
    notification: { title, body },
    data: stringifyData(data),
    ...platformConfig("default"),
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`🔥 FCM_TOPIC | topic="${topic}" | ID: ${response}`);
    return response;
  } catch (error) {
    console.error(`❌ FCM_TOPIC_FAILED | topic="${topic}" | ${error.message}`);
    throw error;
  }
};

/**
 * Send the login OTP to a device via FCM.
 * Fails silently — an OTP notification failure must never block auth.
 */
export const sendOtpNotification = async (fcmToken, otp, userId = null) => {
  if (!fcmToken) return null;

  const message = {
    token: fcmToken,
    notification: { title: "Your Login OTP", body: `Your OTP is ${otp}` },
    data: stringifyData({ type: "otp", otp: String(otp) }),
    android: {
      /** @type {"high" | "normal"} */
      priority: "high",
      notification: { sound: "default", channelId: "otp_channel" },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
          alert: { title: "Your Login OTP", body: `Your OTP is ${otp}` },
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`📲 OTP_PUSH_SENT | User: ${userId ?? 'N/A'}`);
    return response;
  } catch (error) {
    console.error(`❌ OTP_PUSH_FAILED | User: ${userId ?? 'N/A'} | ${error.message}`);
    if (isInvalidTokenError(error.code, error.message)) {
      const e = new Error(`Invalid or expired FCM token: ${error.message}`);
      e.cause = error;
      throw e;
    }
    throw error;
  }
};

/**
 * Validate a token with a dry-run send (does not deliver a notification).
 */
export const validateFcmToken = async (token) => {
  try {
    await admin.messaging().send(
      { token, notification: { title: "test", body: "test" }, data: { test: "true" } },
      true // dryRun
    );
    return true;
  } catch (error) {
    if (isInvalidTokenError(error.code, error.message)) return false;
    return true; // Network or unknown error — assume valid
  }
};
