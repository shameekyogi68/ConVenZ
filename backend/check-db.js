import mongoose from "mongoose";
import dotenv from "dotenv";
import User from "./src/models/userModel.js";

dotenv.config();

const checkUsers = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Connected to MongoDB");
    const count = await User.countDocuments();
    console.log(`📊 Total Users in DB: ${count}`);
    const latestUsers = await User.find().sort({ createdAt: -1 }).limit(5);
    console.log("📝 Latest 5 Users:");
    latestUsers.forEach(u => console.log(` - Phone: ${u.phone}, UserID: ${u.user_id}, Created: ${u.createdAt}`));
    process.exit(0);
  } catch (err) {
    console.error("❌ Error:", err.message);
    process.exit(1);
  }
};

checkUsers();
