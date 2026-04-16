import crypto from 'crypto';
import dotenv from 'dotenv';
import fetch from 'node-fetch';

// Load environment variables
dotenv.config();

const API_BASE = 'http://localhost:5005/api/v1';
const API_SECRET = 'convenz_default_secret_key_2024_@!';

function generateSignature(method, path, timestamp, body = '') {
  const message = `${method}|${path}|${timestamp}|${body}`;
  const hmac = crypto.createHmac('sha256', API_SECRET);
  const signatureBytes = hmac.update(message).digest();
  const signature = signatureBytes.toString('hex');
  return signature;
}

async function testPlansAPI() {
  const timestamp = Date.now().toString();
  const path = '/subscription/plans';
  const body = '';
  const signature = generateSignature('GET', path, timestamp, body);
  
  console.log('=== TESTING PLANS API (MATCHING FRONTEND) ===');
  console.log(`URL: ${API_BASE}${path}`);
  console.log(`Method: GET`);
  console.log(`Timestamp: ${timestamp}`);
  console.log(`Body: "${body}"`);
  console.log(`Message: GET|${path}|${timestamp}|${body}`);
  console.log(`Signature: ${signature}`);
  console.log(`Signature Length: ${signature.length}`);
  
  try {
    const response = await fetch(`${API_BASE}${path}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'x-timestamp': timestamp,
        'x-signature': signature,
      },
    });
    
    const data = await response.json();
    console.log('\n=== RESPONSE ===');
    console.log(`Status: ${response.status}`);
    console.log(`Success: ${data.success}`);
    console.log(`Count: ${data.count}`);
    
    if (data.success && data.data) {
      console.log(`\n✅ SUCCESS: Found ${data.data.length} plans`);
      data.data.forEach((plan, index) => {
        console.log(`${index + 1}. ${plan.name} - $${plan.price}/${plan.duration}`);
        console.log(`   Features: ${plan.features.length} items`);
        console.log(`   Active: ${plan.active}`);
      });
    } else {
      console.log('\n❌ FAILED: No plans returned');
      console.log('Error:', data.message);
    }
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
  }
}

async function testPlansAPIWithQuery() {
  const timestamp = Date.now().toString();
  const path = '/subscription/plans?planType=customer';
  const body = '';
  const signature = generateSignature('GET', path, timestamp, body);
  
  console.log('\n=== TESTING PLANS API WITH QUERY (MATCHING FRONTEND) ===');
  console.log(`URL: ${API_BASE}${path}`);
  console.log(`Method: GET`);
  console.log(`Timestamp: ${timestamp}`);
  console.log(`Body: "${body}"`);
  console.log(`Message: GET|${path}|${timestamp}|${body}`);
  console.log(`Signature: ${signature}`);
  console.log(`Signature Length: ${signature.length}`);
  
  try {
    const response = await fetch(`${API_BASE}${path}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'x-timestamp': timestamp,
        'x-signature': signature,
      },
    });
    
    const data = await response.json();
    console.log('\n=== RESPONSE ===');
    console.log(`Status: ${response.status}`);
    console.log(`Success: ${data.success}`);
    console.log(`Count: ${data.count}`);
    
    if (data.success && data.data) {
      console.log(`\n✅ SUCCESS: Found ${data.data.length} customer plans`);
      data.data.forEach((plan, index) => {
        console.log(`${index + 1}. ${plan.name} - $${plan.price}/${plan.duration}`);
        console.log(`   Features: ${plan.features.length} items`);
        console.log(`   Active: ${plan.active}`);
      });
    } else {
      console.log('\n❌ FAILED: No customer plans returned');
      console.log('Error:', data.message);
    }
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
  }
}

// Run tests
testPlansAPI().then(() => testPlansAPIWithQuery());
