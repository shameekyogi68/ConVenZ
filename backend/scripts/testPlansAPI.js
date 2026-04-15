import mongoose from "mongoose";
import dotenv from "dotenv";
import express from "express";
import { getActivePlans } from "../src/controllers/subscriptionController.js";

// Load environment variables
dotenv.config();

async function testPlansAPI() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/convenz');
    console.log('Connected to MongoDB');

    // Create mock request and response objects
    const mockReq = {
      query: { planType: "customer" }
    };

    let responseData = null;
    let statusCode = null;

    const mockRes = {
      status: (code) => {
        statusCode = code;
        return {
          json: (data) => {
            responseData = data;
            console.log(`Response Status: ${statusCode}`);
            console.log(`Response Data:`, JSON.stringify(data, null, 2));
          }
        };
      }
    };

    // Test the getActivePlans controller function
    console.log('Testing getActivePlans controller...');
    await getActivePlans(mockReq, mockRes);

    // Verify the response
    if (responseData && responseData.success && responseData.data) {
      console.log(`\nSUCCESS: Found ${responseData.data.length} customer plans`);
      responseData.data.forEach((plan, index) => {
        console.log(`${index + 1}. ${plan.name} - $${plan.price}/${plan.duration}`);
      });
    } else {
      console.log('FAILED: No plans returned or response indicates failure');
    }

  } catch (error) {
    console.error('Error testing plans API:', error);
  } finally {
    // Close database connection
    await mongoose.connection.close();
    console.log('Database connection closed');
  }
}

// Run the test
testPlansAPI();
