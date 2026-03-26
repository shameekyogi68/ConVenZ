import mongoose from "mongoose";
import dotenv from "dotenv";

dotenv.config();

const fixBookingIndex = async () => {
  try {
    console.log('🔧 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    const bookingsCollection = db.collection('bookings');

    // Drop the problematic bookingId index
    console.log('\n🗑️  Dropping old bookingId_1 index...');
    try {
      await bookingsCollection.dropIndex('bookingId_1');
      console.log('✅ Dropped bookingId_1 index');
    } catch (err) {
      if (err.code === 27) {
        console.log('ℹ️  Index bookingId_1 does not exist (already removed)');
      } else {
        console.error('⚠️  Error dropping index:', err.message);
      }
    }

    // List all current indexes
    console.log('\n📋 Current indexes:');
    const indexes = await bookingsCollection.indexes();
    indexes.forEach(index => {
      console.log('  -', JSON.stringify(index.key), index.name);
    });

    console.log('\n✅ Database fix complete!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
};

fixBookingIndex();
