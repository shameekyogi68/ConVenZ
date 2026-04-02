import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { sendMultipleNotifications } from './src/utils/sendNotification.js';
import User from './src/models/userModel.js';

dotenv.config();

async function triggerTest() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const users = await User.find({
      fcmToken: { $ne: null, $exists: true, $ne: "" },
      isBlocked: { $ne: true },
    }).lean();

    const tokens = users
      .map((u) => u.fcmToken)
      .filter((t) => typeof t === "string" && t.length > 50);

    console.log(`📱 Testing ${tokens.length} tokens...`);

    const title = "🛠️ System Test: Scheduled Nudge Check";
    const body = "This is a verification check for your scheduled ConVenZ notifications. ✅";
    const data = { type: "MARKETING_NUDGE", hour: "debug_test" };

    const result = await sendMultipleNotifications(tokens, title, body, data);
    
    console.log('\n--- FINAL RESULTS ---');
    console.log(`✅ SUCCESS: ${result.successCount}`);
    console.log(`❌ FAILURE: ${result.failureCount}`);
    
    if (result.results && result.results.length > 0) {
      console.log('\n--- ERROR BREAKDOWN (Sample) ---');
      result.results.filter(r => !r.success).slice(0, 5).forEach((r, i) => {
        console.log(`Failure ${i+1}: Token ending in ${tokens[i].slice(-5)} | Error: ${r.error?.message || r.error}`);
      });
    }

    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('❌ FATAL TEST ERROR:', err.message);
    process.exit(1);
  }
}

triggerTest();
