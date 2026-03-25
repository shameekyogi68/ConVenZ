import mongoose from "mongoose";
import dotenv from "dotenv";
import Plan from "./src/models/planModel.js";

dotenv.config();

const seedPlans = async () => {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("✅ Connected to MongoDB");

    // Define sample plans
    const samplePlans = [
      {
        name: "Basic Flex",
        price: 999,
        duration: "1 month",
        features: [
          "Access to all events",
          "Basic booking system",
          "Standard support",
          "Mobile app access"
        ],
        planType: "customer",
        active: true
      },
      {
        name: "Family Pack",
        price: 2499,
        duration: "3 months",
        features: [
          "Unlimited event access",
          "5 user accounts",
          "Priority booking",
          "Family event calendar",
          "24/7 customer support",
          "Exclusive family discounts"
        ],
        planType: "customer",
        active: true
      },
      {
        name: "Pro Elite",
        price: 4999,
        duration: "6 months",
        features: [
          "Premium event access",
          "Unlimited user accounts",
          "VIP early bird registration",
          "Personal event manager",
          "Analytics & insights dashboard",
          "Custom event planning",
          "Priority 24/7 concierge support",
          "Exclusive partner discounts"
        ],
        planType: "customer",
        active: true
      }
    ];

    // Check if plans already exist
    const existingPlans = await Plan.countDocuments();
    
    if (existingPlans > 0) {
      console.log("⚠️  Plans already exist in the database. Skipping insert to avoid duplicates.");
      console.log(`📊 Current plan count: ${existingPlans}`);
      process.exit(0);
    }

    // Insert plans if they don't exist
    const insertedPlans = await Plan.insertMany(samplePlans);
    console.log(`✅ Successfully seeded ${insertedPlans.length} plans!`);
    
    // Display inserted plans
    insertedPlans.forEach((plan) => {
      console.log(`   • ${plan.name} - ₹${plan.price} (${plan.duration})`);
    });

    process.exit(0);
  } catch (error) {
    console.error("❌ Error seeding plans:", error.message);
    process.exit(1);
  }
};

// Run the seeder
seedPlans();
