import mongoose from "mongoose";
import dotenv from "dotenv";
import Plan from "../src/models/planModel.js";

// Load environment variables
dotenv.config();

async function testPlans() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/convenz');
    console.log('Connected to MongoDB');

    // Test 1: Count all active plans
    const totalActivePlans = await Plan.countDocuments({ active: true });
    console.log(`Total active plans: ${totalActivePlans}`);

    // Test 2: Count customer plans
    const customerPlans = await Plan.countDocuments({ active: true, planType: "customer" });
    console.log(`Active customer plans: ${customerPlans}`);

    // Test 3: Get all customer plans
    const plans = await Plan.find({ active: true, planType: "customer" }).sort({ price: 1 });
    console.log('\nCustomer Plans:');
    plans.forEach((plan, index) => {
      console.log(`${index + 1}. ${plan.name}`);
      console.log(`   Price: $${plan.price}/${plan.duration}`);
      console.log(`   Features: ${plan.features.length} items`);
      console.log(`   Active: ${plan.active}`);
      console.log('');
    });

    // Test 4: Check plan structure
    if (plans.length > 0) {
      const samplePlan = plans[0];
      console.log('Sample Plan Structure:');
      console.log(JSON.stringify(samplePlan.toObject(), null, 2));
    }

  } catch (error) {
    console.error('Error testing plans:', error);
  } finally {
    // Close database connection
    await mongoose.connection.close();
    console.log('Database connection closed');
  }
}

// Run the test
testPlans();
