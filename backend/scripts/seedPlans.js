import mongoose from "mongoose";
import dotenv from "dotenv";
import Plan from "../src/models/planModel.js";

// Load environment variables
dotenv.config();

// Sample plans data
const plans = [
  {
    name: "Basic Plan",
    price: 9.99,
    duration: "1 month",
    features: [
      "Up to 5 bookings per month",
      "Basic customer support",
      "Standard vendor matching",
      "Mobile app access"
    ],
    planType: "customer",
    active: true
  },
  {
    name: "Premium Plan",
    price: 19.99,
    duration: "1 month",
    features: [
      "Unlimited bookings",
      "Priority customer support",
      "Premium vendor matching",
      "Mobile app access",
      "Advanced booking analytics",
      "Discounts on services"
    ],
    planType: "customer",
    active: true
  },
  {
    name: "Professional Plan",
    price: 49.99,
    duration: "1 month",
    features: [
      "Unlimited bookings",
      "24/7 VIP customer support",
      "Elite vendor matching",
      "Mobile app access",
      "Advanced booking analytics",
      "Discounts on services",
      "Custom service requests",
      "Dedicated account manager"
    ],
    planType: "customer",
    active: true
  }
];

async function seedPlans() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/convenz');
    console.log('Connected to MongoDB');

    // Clear existing plans (optional - remove if you want to keep existing plans)
    console.log('Clearing existing plans...');
    await Plan.deleteMany({});
    console.log('Existing plans cleared');

    // Insert new plans
    console.log('Seeding plans...');
    const insertedPlans = await Plan.insertMany(plans);
    console.log(`Successfully seeded ${insertedPlans.length} plans:`);
    
    insertedPlans.forEach((plan, index) => {
      console.log(`${index + 1}. ${plan.name} - $${plan.price}/${plan.duration}`);
      console.log(`   Features: ${plan.features.length} included`);
      console.log(`   Active: ${plan.active}`);
      console.log('');
    });

    // Verify plans were inserted
    const count = await Plan.countDocuments({ active: true });
    console.log(`Total active plans in database: ${count}`);

  } catch (error) {
    console.error('Error seeding plans:', error);
  } finally {
    // Close database connection
    await mongoose.connection.close();
    console.log('Database connection closed');
  }
}

// Run the seeding function
seedPlans();
