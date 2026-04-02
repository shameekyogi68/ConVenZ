import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

const userSchema = new mongoose.Schema({
  fcmToken: String,
  isBlocked: Boolean,
});

const User = mongoose.model('User', userSchema);

async function checkTokens() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to DB');

    const allUsers = await User.find({}).lean();
    console.log(`📊 Total Users: ${allUsers.length}`);

    const withToken = allUsers.filter(u => u.fcmToken);
    console.log(`📱 Users with FCM Token: ${withToken.length}`);

    const shortTokens = withToken.filter(u => u.fcmToken.length <= 50);
    console.log(`⚠️  Tokens <= 50 chars: ${shortTokens.length}`);

    const longTokens = withToken.filter(u => u.fcmToken.length > 50);
    console.log(`✅ Tokens > 50 chars (eligible): ${longTokens.length}`);

    // Print a few token glimpses (first 5 chars)
    if (withToken.length > 0) {
      console.log('\n--- Sample Token Lengths ---');
      withToken.slice(0, 10).forEach((u, i) => {
        console.log(`User ${i+1}: Length ${u.fcmToken.length} | Glimpse: ${u.fcmToken.substring(0, 5)}...`);
      });
    }

    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

checkTokens();
