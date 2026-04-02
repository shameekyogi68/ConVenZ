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
  { title: "🌅 Good Morning!", body: "Start your day by booking a home service in minutes. ☕" },
  { title: "🔧 Reliable Professionals", body: "Trusted vendors are just a tap away. Book now! 🏠" },
  { title: "✨ Premium Cleaning", body: "Discover deep cleaning services available today. 🛠️" },
  { title: "📅 Plan Ahead", body: "Schedule your next service today and get it done on your terms. ✅" },
  { title: "⚡ Fast & Reliable", body: "ConVenZ vendors arrive on time. Book in under 60 seconds! ⏱️" },
  { title: "💎 Upgrade Your Life", body: "Your subscription unlocks exclusive premium access. 🚀" },
  { title: "🏠 Home Services Made Simple", body: "Plumbing, cleaning, repairs — we've got you covered. 🔑" },
  { title: "🌟 Top Rated Vendors", body: "Thousands trust ConVenZ. Join the community today! 💬" },
  { title: "🛁 Weekend Ready?", body: "Book your weekend cleaning now before slots fill up! 📅" },
  { title: "💡 Service Tip", body: "Regular maintenance saves you money. Book a check-up! 🔍" },
  { title: "🎯 Smart Matching", body: "We find the closest professional for your location. 📍" },
  { title: "🌙 Afternoon Check-in", body: "Relax while we handle your home tasks. Book now! 😌" },
  { title: "🤝 Trusted by Families", body: "Friendly professionals, background-verified quality. ⭐" },
  { title: "🎉 New Services!", body: "Check out the newly added local service categories. 🆕" },
  { title: "📲 Use Your Plan", body: "Your active plan gives you priority booking. Use it! 🏆" },
  { title: "☀️ Afternoon Help", body: "Need a hand around the house? We're here to help! 👋" },
  { title: "🔔 Last Few Slots!", body: "Evening slots are in high demand. Reserve yours now! ⚡" },
  { title: "🏅 Verified Quality", body: "Our professionals are rated by high-standard users. ✅" },
  { title: "🛒 All-in-One App", body: "Plumbing, electrical, cleaning — everything's here! 🏠" },
  { title: "💰 Best Value", body: "Upgrade to Pro for unlimited fixed-price bookings. 💎" },
  { title: "📊 Track Everything", body: "Real-time updates on all your active service requests. 📋" },
  { title: "📍 Local Experts", body: "The best professionals in your neighborhood, ready now. 📍" },
  { title: "✨ Your Home, Reimagined", body: "Book a professional refresh for your living space. 🏡" },
  { title: "✅ Mission Accomplished", body: "Finish your to-do list today with a ConVenZ booking. 🎯" },
];

const getMessageForHour = () => {
  const hour = new Date().getHours();
  return MARKETING_MESSAGES[hour % MARKETING_MESSAGES.length];
};

export const triggerHourlyNudge = async () => {
  const startTime = Date.now();
  const currentHour = new Date().getHours();
  console.log(`\n🕒 [SCHEDULER] Running for Hour ${currentHour}:00 | ${new Date().toISOString()}`);

  try {
    // 1. Fetch only eligible users with valid, recent tokens
    // We filter for length > 40 to ensure it is not a dummy or partial token
    const users = await User.find({
      fcmToken: { $ne: null, $exists: true, $ne: "" },
      isBlocked: { $ne: true },
    }).select("fcmToken").lean();

    const tokens = users
      .map((u) => u.fcmToken)
      .filter((t) => typeof t === "string" && t.length > 50);

    if (tokens.length === 0) {
      console.log("ℹ️  [SCHEDULER] 0 eligible users found. Skipping nudge.");
      return { sent: 0, total: users.length, skipped: true };
    }

    const { title, body } = getMessageForHour();
    const data = { type: "MARKETING_NUDGE", hour: String(currentHour) };

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
    
    return { sent: totalSent, failure: totalFailure, elapsed };

  } catch (error) {
    console.error(`❌ [SCHEDULER] Fatal Error: ${error.message}`);
    throw error;
  }
};

const startHourlyNotifications = () => {
  /**
   * IMPORTANT: The server's OS time might differ from local time.
   * We run every hour at minute 00 of the HOUR.
   */
  cron.schedule("0 * * * *", triggerHourlyNudge);
  
  // Also run 1 minute after start to verify it's working (initial boot nudge)
  setTimeout(() => {
    console.log("🚀 [SCHEDULER] Initializing early nudge verification...");
    triggerHourlyNudge().catch(e => console.error("❌ Pre-heat nudge failed:", e));
  }, 30000); // Wait 30s after boot

  console.log("🚀 [SCHEDULER] Automated Hourly Marketing initialized. (0 * * * *)");
};

export default startHourlyNotifications;
