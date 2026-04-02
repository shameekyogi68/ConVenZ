import mongoose from "mongoose";
import dotenv from "dotenv";
import User from "./src/models/userModel.js";
import { triggerHourlyNudge } from "./src/utils/scheduler.js";

dotenv.config();

async function debugNudgeSystem() {
  try {
    console.log("🔍 [DEBUG] Starting nudge system audit...");
    
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ DB Connected");

    // 1. Check users with FCM tokens
    const allUsers = await User.find({}).select("phone fcmToken isBlocked").lean();
    
    const eligibleUsers = allUsers.filter(u => 
      u.fcmToken && 
      typeof u.fcmToken === 'string' && 
      u.fcmToken.length > 20 && 
      !u.isBlocked
    );

    console.log(`📊 Statistics:`);
    console.log(`   - Total Users: ${allUsers.length}`);
    console.log(`   - Eligible Users (Token > 20 chars): ${eligibleUsers.length}`);

    if (eligibleUsers.length === 0) {
      console.log("❌ CRITICAL: No active users with valid FCM tokens found in DB.");
    } else {
      console.log("✅ Top 5 Eligible tokens found:");
      eligibleUsers.slice(0, 5).forEach((u, i) => {
        console.log(`     ${i+1}. Phone: ${u.phone} | Token: ${u.fcmToken.substring(0, 30)}...`);
      });
      
      console.log("\n🚀 [DEBUG] Triggering manual nudge test...");
      const result = await triggerHourlyNudge();
      console.log("🏁 Test result summary:", JSON.stringify(result, null, 2));
    }

    await mongoose.disconnect();
  } catch (error) {
    console.error("❌ Debug failed:", error);
    process.exit(1);
  }
}

debugNudgeSystem();
