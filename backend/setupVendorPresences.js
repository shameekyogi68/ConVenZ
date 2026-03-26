import mongoose from "mongoose";
import dotenv from "dotenv";
import Vendor from "./src/models/vendorModel.js";
import VendorPresence from "./src/models/vendorPresenceModel.js";

dotenv.config();

const setupVendorPresences = async () => {
  try {
    console.log("🔧 === VENDOR PRESENCE SETUP ===\n");

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Connected to MongoDB\n");

    // Get all vendors
    const vendors = await Vendor.find();
    console.log(`📊 Found ${vendors.length} vendors\n`);

    if (vendors.length === 0) {
      console.log("❌ No vendors found. Create vendors first!");
      process.exit(1);
    }

    // Create presence for each vendor
    let created = 0;
    let updated = 0;
    let skipped = 0;

    for (const vendor of vendors) {
      console.log(`\n🔍 Processing vendor ${vendor.vendor_id}:`);
      console.log(`   Name: ${vendor.name || 'N/A'}`);
      console.log(`   Phone: ${vendor.phone}`);
      console.log(`   Services: ${vendor.selectedServices?.join(', ') || 'None'}`);
      
      // Check if presence already exists
      const existingPresence = await VendorPresence.findOne({ vendorId: vendor.vendor_id });
      
      if (existingPresence) {
        console.log(`   ⚠️  Presence exists - Status: ${existingPresence.online ? 'Online' : 'Offline'}`);
        
        // Update to ensure location is set
        if (vendor.location?.coordinates?.length === 2) {
          existingPresence.currentLocation = {
            type: "Point",
            coordinates: vendor.location.coordinates
          };
          existingPresence.currentAddress = vendor.address || "Location not set";
          existingPresence.lastSeen = new Date();
          // Keep current online status
          await existingPresence.save();
          console.log(`   ✅ Updated location`);
          updated++;
        } else {
          console.log(`   ⚠️  Vendor has no location coordinates`);
          skipped++;
        }
        continue;
      }

      // Create new presence
      if (!vendor.location?.coordinates || vendor.location.coordinates.length !== 2) {
        console.log(`   ❌ Cannot create presence - vendor has no location`);
        skipped++;
        continue;
      }

      const presence = await VendorPresence.create({
        vendorId: vendor.vendor_id,
        online: true, // Set online by default for testing
        lastSeen: new Date(),
        currentLocation: {
          type: "Point",
          coordinates: vendor.location.coordinates
        },
        currentAddress: vendor.address || "Address not set"
      });

      console.log(`   ✅ Created presence - Set ONLINE for testing`);
      created++;
    }

    // Summary
    console.log("\n" + "=".repeat(60));
    console.log("📊 SETUP SUMMARY");
    console.log("=".repeat(60));
    console.log(`✅ Created: ${created} presences`);
    console.log(`🔄 Updated: ${updated} presences`);
    console.log(`⚠️  Skipped: ${skipped} vendors (missing location)`);

    // Final status check
    const onlineCount = await VendorPresence.countDocuments({ online: true });
    console.log(`\n🟢 Online vendors: ${onlineCount}`);

    if (onlineCount === 0) {
      console.log("\n⚠️  WARNING: No vendors are online!");
      console.log("   To set vendors online, run:");
      console.log("   db.vendorpresences.updateMany({}, { $set: { online: true } })");
    } else {
      console.log("\n✅ System ready to accept bookings!");
    }

    // List online vendors
    if (onlineCount > 0) {
      console.log("\n📋 Online Vendors:");
      const onlinePresences = await VendorPresence.find({ online: true });
      
      for (const presence of onlinePresences) {
        const vendor = await Vendor.findOne({ vendor_id: presence.vendorId });
        console.log(`   🟢 Vendor ${presence.vendorId}: ${vendor?.name || vendor?.phone || 'Unknown'}`);
        console.log(`      Services: ${vendor?.selectedServices?.join(', ') || 'None'}`);
        console.log(`      Location: ${presence.currentAddress}`);
      }
    }

    console.log("\n✅ Setup completed successfully!");
    process.exit(0);

  } catch (error) {
    console.error("❌ Setup failed:", error.message);
    console.error(error.stack);
    process.exit(1);
  }
};

// Run setup
setupVendorPresences();
