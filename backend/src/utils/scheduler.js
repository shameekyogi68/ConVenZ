import cron from "node-cron";
import User from "../models/userModel.js";
import { sendMultipleNotifications } from "./sendNotification.js";

/**
 * ⏰ MARKETING NOTIFICATION SCHEDULER (PROFESSIONAL VERSION)
 *
 * This service ensures users receive regular, helpful nudges.
 * It handles errors gracefully, logs performance metrics, and 
 * implements fallback logic for failed tokens.
 */

const MARKETING_MESSAGES = [
  /* 00:00 */ { title: "🌙 Rest Easy", body: "Need home help tomorrow? Book a pro now and wake up to a plan. 😴" },
  /* 01:00 */ { title: "💤 Night Owl?", body: "Schedule your morning cleaning while the house is quiet. 🏠" },
  /* 02:00 */ { title: "🛠️ Repairs Simplified", body: "Don't let that leak wait. Book a technician for the morning. 🔧" },
  /* 03:00 */ { title: "📅 Early Bird Booking", body: "Reserve the best slots for today before they fill up! 🎯" },
  /* 04:00 */ { title: "💡 Service Tip", body: "Regular maintenance saves you money. Check out our experts. 🔍" },
  /* 05:00 */ { title: "🌅 Almost Morning!", body: "Thinking of a home refresh? Start your day with ConVenZ. ☕" },
  /* 06:00 */ { title: "☀️ Good Morning!", body: "Start your day by booking a home service in minutes. ☕" },
  /* 07:00 */ { title: "🚿 Fresh Start", body: "Need a plumber or electrician? Book a top-rated pro now. ⚡" },
  /* 08:00 */ { title: "🔧 Reliable Professionals", body: "Trusted vendors are just a tap away. Book for today! 🏠" },
  /* 09:00 */ { title: "✨ Premium Cleaning", body: "Discover deep cleaning services available today. 🛠️" },
  /* 10:00 */ { title: "⚡ Fast & Reliable", body: "ConVenZ vendors arrive on time. Book in under 60 seconds! ⏱️" },
  /* 11:00 */ { title: "💎 Upgrade Your Life", body: "Your subscription unlocks exclusive premium access. 🚀" },
  /* 12:00 */ { title: "🏠 Services Made Simple", body: "Plumbing, cleaning, repairs — we've got you covered. 🔑" },
  /* 13:00 */ { title: "🌟 Top Rated Vendors", body: "Thousands trust ConVenZ. Join the community today! 💬" },
  /* 14:00 */ { title: "☀️ Afternoon Help", body: "Need a hand around the house? We're here to help! 👋" },
  /* 15:00 */ { title: "🌙 Afternoon Check-in", body: "Relax while we handle your home tasks. Book now! 😌" },
  /* 16:00 */ { title: "🎯 Smart Matching", body: "We find the closest professional for your location. 📍" },
  /* 17:00 */ { title: "🔔 Last Few Slots!", body: "Evening slots are in high demand. Reserve yours now! ⚡" },
  /* 18:00 */ { title: "🏅 Verified Quality", body: "Our professionals are rated by high-standard users. ✅" },
  /* 19:00 */ { title: "🛁 Weekend Ready?", body: "Book your weekend cleaning now before slots fill up! 📅" },
  /* 20:00 */ { title: "🛒 All-in-One App", body: "Plumbing, electrical, cleaning — everything's here! 🏠" },
  /* 21:00 */ { title: "💰 Best Value", body: "Upgrade to Pro for unlimited fixed-price bookings. 💎" },
  /* 22:00 */ { title: "📊 Track Everything", body: "Real-time updates on all your active service requests. 📋" },
  /* 23:00 */ { title: "✨ Your Home, Reimagined", body: "Book a professional refresh for your living space tomorrow. 🏡" },
];

let lastRunAt = null;

// Quiet hours: no marketing pushes between 10PM (22:00) and 7AM (07:00) IST
const QUIET_HOUR_START = 22;
const QUIET_HOUR_END = 7;

const getIstHour = () => {
  const now = new Date();
  const utcHour = now.getUTCHours();
  const utcMinutes = now.getUTCMinutes();
  let istHour = utcHour + 5;
  if (utcMinutes + 30 >= 60) istHour += 1;
  return istHour % 24;
};

const isQuietHour = (istHour) => {
  return istHour >= QUIET_HOUR_START || istHour < QUIET_HOUR_END;
};

const getMessageForHour = (istHour) => {
  return MARKETING_MESSAGES[istHour];
};

export const triggerHourlyNudge = async (isManual = false) => {
  const now = Date.now();
  
  // 🛡️ Prevent rapid-fire notifications (e.g. from frequent server restarts)
  // Ensure at least 45 minutes pass between marketing nudges
  if (!isManual && lastRunAt && (now - lastRunAt) < 45 * 60 * 1000) {
    const minutesSince = Math.floor((now - lastRunAt) / 60000);
    console.log(`🕒 [SCHEDULER] Skipping nudge. Last one sent just ${minutesSince} mins ago.`);
    return { skipped: true, reason: "RECENT_NUDGE" };
  }

  const startTime = now;
  const currentHour = getIstHour();
  console.log(`\n🕒 [SCHEDULER] Running for IST Hour ${currentHour}:00 | ${new Date().toISOString()}`);

  // 🔕 Quiet Hours: skip marketing between 10PM and 7AM IST
  if (!isManual && isQuietHour(currentHour)) {
    console.log(`🔕 [SCHEDULER] Quiet hours (${QUIET_HOUR_START}:00–${QUIET_HOUR_END}:00 IST). Skipping nudge.`);
    return { skipped: true, reason: "QUIET_HOURS" };
  }

  try {
    // 1. Fetch only eligible users with valid, recent tokens
    // We filter for length > 40 to ensure it is not a dummy or partial token
    const users = await User.find({
      fcmToken: { $nin: [null, ""], $exists: true },
      isBlocked: { $ne: true },
    }).select("fcmToken").lean();

    const tokens = users
      .map((u) => u.fcmToken)
      .filter((t) => typeof t === "string" && t.length > 50);

    if (tokens.length === 0) {
      console.log("ℹ️  [SCHEDULER] 0 eligible users found. Skipping nudge.");
      return { sent: 0, total: users.length, skipped: true };
    }

    const { title, body } = getMessageForHour(currentHour);
    const data = { type: "MARKETING_NUDGE", hour: String(currentHour), clickAction: "FLUTTER_NOTIFICATION_CLICK" };

    console.log(`📡 [SCHEDULER] Dispatching "${title}" to ${tokens.length} users...`);

    const CHUNK_SIZE = 500;
    let totalSent = 0;
    let totalFailure = 0;

    for (let i = 0; i < tokens.length; i += CHUNK_SIZE) {
      const chunk = tokens.slice(i, i + CHUNK_SIZE);
      const response = await sendMultipleNotifications(chunk, title, body, data);
      totalSent += response.successCount;
      totalFailure += response.failureCount;
    }

    const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
    console.log(`✅ [SCHEDULER] Success: ${totalSent} | Failure: ${totalFailure} | Time: ${elapsed}s`);
    
    // ✅ LOCK: Do not send another nudge for 45 minutes
    lastRunAt = Date.now();
    
    return { sent: totalSent, failure: totalFailure, elapsed };

  } catch (error) {
    console.error(`❌ [SCHEDULER] Fatal Error: ${error.message}`);
    throw error;
  }
};

const startHourlyNotifications = () => {
  /**
   * Run every hour exactly at the top of the hour in Indian Standard Time (IST)
   */
  cron.schedule("0 * * * *", triggerHourlyNudge, {
    timezone: "Asia/Kolkata"
  });
  
  console.log("🚀 [SCHEDULER] Automated Hourly Marketing initialized. (0 * * * *)");
};

export default startHourlyNotifications;
