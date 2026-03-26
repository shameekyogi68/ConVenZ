import mongoose from "mongoose";
import dotenv from "dotenv";

dotenv.config();

const setupVendorPresences = async () => {
  try {
    console.log("🔧 === VENDOR PRESENCE SETUP (Using Existing Schema) ===\n");

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Connected to MongoDB\n");

    // Get vendors collection directly
    const vendorsCollection = mongoose.connection.db.collection('vendors');
    const vendors = await vendorsCollection.find().toArray();
    
    console.log(`📊 Found ${vendors.length} vendors\n`);

    if (vendors.length === 0) {
      console.log("❌ No vendors found!");
      process.exit(1);
    }

    const vendorPresencesCollection = mongoose.connection.db.collection('vendorpresences');

    let created = 0;
    let updated = 0;
    let skipped = 0;

    for (const vendor of vendors) {
      const vendorId = vendor.vendorId || vendor._id.toString();
      
      console.log(`\n🔍 Processing vendor:`);
      console.log(`   ID: ${vendorId}`);
      console.log(`   Name: ${vendor.vendorName || 'N/A'}`);
      console.log(`   Mobile: ${vendor.mobile}`);
      console.log(`   Services: ${vendor.selectedServices?.join(', ') || 'None'}`);
      
      // Check if presence exists
      const existingPresence = await vendorPresencesCollection.findOne({ 
        vendorId: vendorId 
      });
      
      if (existingPresence) {
        console.log(`   ⚠️  Presence exists - Status: ${existingPresence.online ? 'Online 🟢' : 'Offline 🔴'}`);
        
        // Update to set online
        await vendorPresencesCollection.updateOne(
          { vendorId: vendorId },
          { 
            $set: { 
              online: true,
              lastSeen: new Date(),
              currentLocation: {
                type: "Point",
                coordinates: [77.5946, 12.9716] // Default Bangalore coordinates
              },
              currentAddress: vendor.businessAddress || "Bangalore, Karnataka"
            }
          }
        );
        console.log(`   ✅ Updated - Set ONLINE`);
        updated++;
        continue;
      }

      // Create new presence
      const presenceDoc = {
        vendorId: vendorId,
        online: true,
        lastSeen: new Date(),
        currentLocation: {
          type: "Point",
          coordinates: [77.5946, 12.9716] // Default Bangalore coordinates
        },
        currentAddress: vendor.businessAddress || "Bangalore, Karnataka",
        createdAt: new Date(),
        updatedAt: new Date()
      };

      await vendorPresencesCollection.insertOne(presenceDoc);
      console.log(`   ✅ Created presence - Set ONLINE`);
      created++;
    }

    // Summary
    console.log("\n" + "=".repeat(60));
    console.log("📊 SETUP SUMMARY");
    console.log("=".repeat(60));
    console.log(`✅ Created: ${created} presences`);
    console.log(`🔄 Updated: ${updated} presences`);
    console.log(`⚠️  Skipped: ${skipped} vendors`);

    // Final status check
    const onlineCount = await vendorPresencesCollection.countDocuments({ online: true });
    console.log(`\n🟢 Online vendors: ${onlineCount}`);

    if (onlineCount > 0) {
      console.log("\n✅ System ready to accept bookings!");
      
      // List online vendors
      console.log("\n📋 Online Vendors:");
      const onlinePresences = await vendorPresencesCollection.find({ online: true }).toArray();
      
      for (const presence of onlinePresences) {
        const vendor = await vendorsCollection.findOne({ 
          $or: [
            { vendorId: presence.vendorId },
            { _id: new mongoose.Types.ObjectId(presence.vendorId) }
          ]
        });
        
        if (vendor) {
          console.log(`\n   🟢 ${vendor.vendorName || vendor.mobile}`);
          console.log(`      ID: ${presence.vendorId}`);
          console.log(`      Services: ${vendor.selectedServices?.join(', ') || 'None'}`);
          console.log(`      Business: ${vendor.businessName || 'N/A'}`);
          console.log(`      Location: ${presence.currentAddress}`);
        }
      }
    }

    // Create 2dsphere index on currentLocation
    try {
      await vendorPresencesCollection.createIndex({ currentLocation: "2dsphere" });
      console.log("\n✅ Created geospatial index on vendor presences");
    } catch (e) {
      console.log("\n⚠️  Index already exists or couldn't be created");
    }

    console.log("\n🎉 Setup completed successfully!");
    console.log("\n📝 Next steps:");
    console.log("   1. Test booking creation from Flutter app");
    console.log("   2. Check vendor notifications");
    console.log("   3. Update vendor FCM tokens if needed");
    
    process.exit(0);

  } catch (error) {
    console.error("❌ Setup failed:", error.message);
    console.error(error.stack);
    process.exit(1);
  }
};

// Run setup
setupVendorPresences();
