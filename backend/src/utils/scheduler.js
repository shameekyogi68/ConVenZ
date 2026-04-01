import cron from "node-cron";
import User from "../models/userModel.js";
import { sendMultipleNotifications } from "./sendNotification.js";

/**
 * ⏰ MARKETING NOTIFICATION SCHEDULER
 *
 * Sends rotating, contextual push notifications to all active users
 * on an hourly schedule. Messages are varied to avoid fatigue.
 * 
 * Schedule: Every hour at the top of the hour (e.g., 9:00, 10:00, 11:00)
 * Delivery: Chunked into batches of 500 (FCM multicast limit)
 * Safety:   Skips users with no FCM token or who are blocked
 */

// ─────────────────────────────────────────────────────
// 📣 ROTATING MARKETING MESSAGE POOL
// Messages are selected by hour-of-day index to ensure
// variety throughout the day without being random (so 
// emails/notifications are fully auditable by hour).
// ─────────────────────────────────────────────────────
const MARKETING_MESSAGES = [
  {
    title: "🌅 Good Morning from ConVenZ!",
    body: "Start your day right — book a home service in minutes. ☕",
  },
  {
    title: "🔧 Your Home Deserves the Best",
    body: "Trusted professionals just a tap away. Book your service now! 🏠",
  },
  {
    title: "✨ Premium Services, Unbeatable Prices",
    body: "Discover home cleaning, repairs & more. Check today's availability! 🛠️",
  },
  {
    title: "📅 Plan Ahead, Stress Less",
    body: "Schedule your next home service today and get it done on your terms. ✅",
  },
  {
    title: "⚡ Fast. Reliable. Trusted.",
    body: "ConVenZ vendors arrive on time, every time. Book in under 60 seconds! ⏱️",
  },
  {
    title: "💎 Upgrade Your Lifestyle",
    body: "Your subscription unlocks exclusive access to premium services. Explore now! 🚀",
  },
  {
    title: "🏠 Home Services Made Simple",
    body: "From plumbing to cleaning — we've got you covered, anytime. Tap to book! 🔑",
  },
  {
    title: "🌟 Your Satisfaction is Our Priority",
    body: "Thousands of happy customers trust ConVenZ. Join the community today! 💬",
  },
  {
    title: "🛁 Weekend Ready?",
    body: "Deep cleaning, repairs & more — book for the weekend before slots fill up! 📅",
  },
  {
    title: "💡 Did You Know?",
    body: "Regular home maintenance saves up to 30% on repair costs. Book a check-up! 🔍",
  },
  {
    title: "🎯 Right Vendor, Right Time",
    body: "Our smart matching finds the closest professional for you. Try it now! 📍",
  },
  {
    title: "🌙 Evening Slots Available",
    body: "Book an after-work service. Our vendors work around your schedule. 🕐",
  },
  {
    title: "🤝 Trusted by 1000+ Families",
    body: "See why ConVenZ is the #1 home services app in your area! ⭐",
  },
  {
    title: "🆕 New Services Available!",
    body: "We just added new categories. Check out what's new in your area. 🎉",
  },
  {
    title: "📲 Quick Reminder",
    body: "Don't forget — your active plan gives you priority booking. Use it! 🏆",
  },
  {
    title: "☀️ Afternoon Pick-Me-Up",
    body: "Take a break and let us handle your home tasks. Book now, relax later! 😌",
  },
  {
    title: "🔔 Slots Filling Fast!",
    body: "Evening and weekend slots are in high demand. Reserve yours now! ⚡",
  },
  {
    title: "🏅 Quality Guaranteed",
    body: "All ConVenZ professionals are background-verified and rated by real users. ✅",
  },
  {
    title: "🛒 One App, All Services",
    body: "Plumbing, electrical, cleaning, carpentry & more. Everything in one place. 🏠",
  },
  {
    title: "💰 Save Big with a Plan",
    body: "Upgrade your subscription and unlock unlimited bookings at a fixed price. 💎",
  },
  {
    title: "📊 Track Your Services",
    body: "View all your bookings, statuses, and history — all in real time. 📋",
  },
  {
    title: "🌍 We're Expanding!",
    body: "ConVenZ is now available in more areas. Check if we serve your location! 📍",
  },
  {
    title: "✅ Last Chance Today!",
    body: "Still have pending tasks at home? Book before the day ends! 🌆",
  },
];

// ─────────────────────────────────────────────────────
// 🎯 Get the marketing message for the current hour
// ─────────────────────────────────────────────────────
const getMessageForHour = () => {
  const hour = new Date().getHours(); // 0–23
  return MARKETING_MESSAGES[hour % MARKETING_MESSAGES.length];
};

// ─────────────────────────────────────────────────────
// 📡 CORE NUDGE LOGIC (exported for manual test trigger)
// ─────────────────────────────────────────────────────
export const triggerHourlyNudge = async () => {
  const startTime = Date.now();
  console.log(`\n🕒 [SCHEDULER] Hourly nudge started | ${new Date().toISOString()}`);

  try {
    // 1. Fetch all active users who have a valid FCM token
    const users = await User.find({
      fcmToken: { $ne: null, $exists: true, $ne: "" },
      isBlocked: { $ne: true },
    }).select("fcmToken").lean();

    const tokens = users
      .map((u) => u.fcmToken)
      .filter((t) => typeof t === "string" && t.length > 10);

    if (tokens.length === 0) {
      console.log("ℹ️  [SCHEDULER] No eligible users found. Skipping.");
      return { sent: 0, skipped: true };
    }

    // 2. Pick message for this hour
    const { title, body } = getMessageForHour();
    const data = {
      type: "MARKETING_NUDGE",
      timestamp: new Date().toISOString(),
      hour: String(new Date().getHours()),
    };

    console.log(`📡 [SCHEDULER] Sending "${title}" to ${tokens.length} users...`);

    // 3. Send in chunks of 500 (FCM multicast limit)
    const CHUNK_SIZE = 500;
    let totalSent = 0;
    for (let i = 0; i < tokens.length; i += CHUNK_SIZE) {
      const chunk = tokens.slice(i, i + CHUNK_SIZE);
      const chunkNum = Math.floor(i / CHUNK_SIZE) + 1;
      console.log(`   📦 Chunk ${chunkNum} of ${Math.ceil(tokens.length / CHUNK_SIZE)} (${chunk.length} tokens)`);
      await sendMultipleNotifications(chunk, title, body, data);
      totalSent += chunk.length;
    }

    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log(`✅ [SCHEDULER] Done | ${totalSent} notifications sent in ${elapsed}s`);
    return { sent: totalSent, skipped: false };

  } catch (error) {
    console.error(`❌ [SCHEDULER] Error: ${error.message}`);
    throw error;
  }
};

// ─────────────────────────────────────────────────────
// 🚀 START THE SCHEDULER (called once from server.js)
// ─────────────────────────────────────────────────────
const startHourlyNotifications = () => {
  // "0 * * * *" = at minute 0 of every hour
  cron.schedule("0 * * * *", triggerHourlyNudge, {
    scheduled: true,
    timezone: "Asia/Kolkata", // IST — adjust if needed
  });

  console.log("🚀 [SCHEDULER] Hourly marketing nudge initialized (cron: 0 * * * * | IST)");
};

export default startHourlyNotifications;
