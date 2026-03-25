import mongoose from "mongoose";
import dotenv from "dotenv";
import Vendor from "./src/models/vendorModel.js";
import VendorPresence from "./src/models/vendorPresenceModel.js";
import User from "./src/models/userModel.js";
import Booking from "./src/models/bookingModel.js";

dotenv.config();

const testBookingSystem = async () => {
  try {
    console.log("🧪 === BOOKING SYSTEM TEST ===\n");

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Connected to MongoDB\n");

    // Test 1: Check if collections exist
    console.log("📋 Test 1: Database Collections");
    const collections = await mongoose.connection.db.listCollections().toArray();
    const collectionNames = collections.map(c => c.name);
    
    console.log(`   Users: ${collectionNames.includes('users') ? '✅' : '❌'}`);
    console.log(`   Vendors: ${collectionNames.includes('vendors') ? '✅' : '❌'}`);
    console.log(`   VendorPresences: ${collectionNames.includes('vendorpresences') ? '✅' : '❌'}`);
    console.log(`   Bookings: ${collectionNames.includes('bookings') ? '✅' : '❌'}`);

    // Test 2: Check User model
    console.log("\n👤 Test 2: User Model");
    const userCount = await User.countDocuments();
    console.log(`   Total Users: ${userCount}`);
    if (userCount > 0) {
      const sampleUser = await User.findOne();
      console.log(`   ✅ Sample User: ${sampleUser.name || sampleUser.phone} (ID: ${sampleUser.user_id})`);
      console.log(`      - Has FCM Token: ${sampleUser.fcmToken ? '✅' : '❌'}`);
      console.log(`      - Has Location: ${sampleUser.location?.coordinates?.length === 2 ? '✅' : '❌'}`);
    }

    // Test 3: Check Vendor model
    console.log("\n🏢 Test 3: Vendor Model");
    const vendorCount = await Vendor.countDocuments();
    console.log(`   Total Vendors: ${vendorCount}`);
    if (vendorCount > 0) {
      const sampleVendor = await Vendor.findOne();
      console.log(`   ✅ Sample Vendor: ${sampleVendor.name || sampleVendor.phone} (ID: ${sampleVendor.vendor_id})`);
      console.log(`      - Services: ${sampleVendor.selectedServices?.join(', ') || 'None'}`);
      console.log(`      - FCM Tokens: ${sampleVendor.fcmTokens?.length || 0}`);
      console.log(`      - Location: ${sampleVendor.location?.coordinates?.length === 2 ? '✅' : '❌'}`);
    } else {
      console.log(`   ⚠️  No vendors found - you'll need to create vendors for the system to work`);
    }

    // Test 4: Check VendorPresence model
    console.log("\n🟢 Test 4: Vendor Presence");
    const presenceCount = await VendorPresence.countDocuments();
    const onlineCount = await VendorPresence.countDocuments({ online: true });
    console.log(`   Total Presences: ${presenceCount}`);
    console.log(`   Online Vendors: ${onlineCount}`);
    if (onlineCount === 0 && vendorCount > 0) {
      console.log(`   ⚠️  No vendors are online - set vendors online to receive bookings`);
    }

    // Test 5: Check Booking model
    console.log("\n📅 Test 5: Booking Model");
    const bookingCount = await Booking.countDocuments();
    console.log(`   Total Bookings: ${bookingCount}`);
    if (bookingCount > 0) {
      const statusCounts = await Booking.aggregate([
        { $group: { _id: "$status", count: { $sum: 1 } } }
      ]);
      console.log(`   Status Breakdown:`);
      statusCounts.forEach(s => console.log(`      - ${s._id}: ${s.count}`));
    }

    // Test 6: Vendor Matching Dependencies
    console.log("\n🎯 Test 6: Vendor Matching Requirements");
    const readyVendors = await Vendor.countDocuments({
      selectedServices: { $exists: true, $ne: [] },
      'location.coordinates': { $exists: true }
    });
    console.log(`   Vendors with services & location: ${readyVendors}`);
    
    const onlineReadyVendors = await VendorPresence.countDocuments({
      online: true,
      'currentLocation.coordinates': { $exists: true }
    });
    console.log(`   Online vendors with location: ${onlineReadyVendors}`);

    if (readyVendors > 0 && onlineReadyVendors > 0) {
      console.log(`   ✅ System ready for vendor matching!`);
    } else {
      console.log(`   ⚠️  System not ready - need vendors with services, locations, and online status`);
    }

    // Test 7: Model Indexes
    console.log("\n📊 Test 7: Geospatial Indexes");
    const userIndexes = await User.collection.getIndexes();
    const vendorIndexes = await Vendor.collection.getIndexes();
    const bookingIndexes = await Booking.collection.getIndexes();
    
    console.log(`   User location index: ${userIndexes.location ? '✅' : '❌'}`);
    console.log(`   Vendor location index: ${vendorIndexes.location ? '✅' : '❌'}`);
    console.log(`   Booking location index: ${bookingIndexes.location ? '✅' : '❌'}`);

    // Summary
    console.log("\n" + "=".repeat(60));
    console.log("📊 SYSTEM STATUS SUMMARY");
    console.log("=".repeat(60));
    
    const issues = [];
    const warnings = [];
    
    if (!collectionNames.includes('vendors')) {
      issues.push("❌ Vendors collection missing");
    }
    if (!collectionNames.includes('vendorpresences')) {
      issues.push("❌ VendorPresences collection missing");
    }
    if (vendorCount === 0) {
      warnings.push("⚠️  No vendors created yet");
    }
    if (onlineCount === 0 && vendorCount > 0) {
      warnings.push("⚠️  No vendors are online");
    }
    if (readyVendors === 0 && vendorCount > 0) {
      warnings.push("⚠️  Vendors missing services or locations");
    }

    if (issues.length === 0 && warnings.length === 0) {
      console.log("✅ All systems operational!");
      console.log("✅ Booking system ready to accept requests");
    } else {
      if (issues.length > 0) {
        console.log("\n🚨 CRITICAL ISSUES:");
        issues.forEach(i => console.log(`   ${i}`));
      }
      if (warnings.length > 0) {
        console.log("\n⚠️  WARNINGS:");
        warnings.forEach(w => console.log(`   ${w}`));
      }
    }

    console.log("\n📝 NEXT STEPS:");
    if (vendorCount === 0) {
      console.log("   1. Create vendors in MongoDB");
      console.log("   2. Set vendor services and locations");
      console.log("   3. Create vendor presence records");
      console.log("   4. Set vendors online");
    } else if (onlineCount === 0) {
      console.log("   1. Set vendors online in vendorpresences collection");
      console.log("   2. Test booking creation from Flutter app");
    } else {
      console.log("   1. Test booking creation from Flutter app");
      console.log("   2. Verify FCM notifications on both devices");
      console.log("   3. Test vendor acceptance flow");
    }

    console.log("\n✅ Test completed successfully!");
    process.exit(0);

  } catch (error) {
    console.error("❌ Test failed:", error.message);
    console.error(error.stack);
    process.exit(1);
  }
};

// Run test
testBookingSystem();
