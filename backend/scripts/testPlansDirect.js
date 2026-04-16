import mongoose from 'mongoose';
import dotenv from 'dotenv';
import Plan from '../src/models/planModel.js';

// Load environment variables
dotenv.config();

async function testPlansDirect() {
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
      
      // Test 5: Create mock request object
      const mockReq = {
        query: { planType: "customer" }
      };
      
      // Test 6: Create mock response object
      let responseData = null;
      let statusCode = null;
      
      const mockRes = {
        status: (code) => {
          statusCode = code;
          return {
            json: (data) => {
              responseData = data;
              console.log(`\nController Response Status: ${statusCode}`);
              console.log(`Controller Response Data:`, JSON.stringify(data, null, 2));
            }
          };
        }
      };

      // Test 7: Import and test controller function
      const { getActivePlans } = await import('../src/controllers/subscriptionController.js');
      
      console.log('\nTesting getActivePlans controller...');
      await getActivePlans(mockReq, mockRes);

      // Verify the response
      if (responseData && responseData.success && responseData.data) {
        console.log(`\n✅ SUCCESS: Controller returned ${responseData.data.length} customer plans`);
        responseData.data.forEach((plan, index) => {
          console.log(`${index + 1}. ${plan.name} - $${plan.price}/${plan.duration}`);
        });
      } else {
        console.log('\n❌ FAILED: Controller did not return expected format');
      }
    }

  } catch (error) {
    console.error('Error testing plans:', error);
  } finally {
    // Close database connection
    await mongoose.connection.close();
    console.log('\nDatabase connection closed');
  }
}

// Run the test
testPlansDirect();
