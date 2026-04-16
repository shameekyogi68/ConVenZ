import crypto from 'crypto';
import dotenv from 'dotenv';
import fetch from 'node-fetch';

// Load environment variables
dotenv.config();

const API_BASE = 'http://localhost:5005/api/v1';
const API_SECRET = 'convenz_default_secret_key_2024_@!';

function generateSignature(method, path, timestamp, body = '') {
  const message = `${method}|${path}|${timestamp}|${body}`;
  return crypto.createHmac('sha256', API_SECRET).update(message).digest('hex');
}

async function testPlansAPI() {
  const timestamp = Date.now().toString();
  const path = '/subscription/plans';
  const body = '';
  const signature = generateSignature('GET', path, timestamp, body);
  
  console.log('Testing Plans API with correct path...');
  console.log(`URL: ${API_BASE}${path}`);
  console.log(`Timestamp: ${timestamp}`);
  console.log(`Body: "${body}"`);
  console.log(`Message: GET|${path}|${timestamp}|${body}`);
  console.log(`Signature: ${signature}`);
  
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
    console.log('\nResponse Status:', response.status);
    console.log('Response Data:', JSON.stringify(data, null, 2));
    
    if (data.success && data.data) {
      console.log(`\n✅ SUCCESS: Found ${data.data.length} plans`);
      data.data.forEach((plan, index) => {
        console.log(`${index + 1}. ${plan.name} - $${plan.price}/${plan.duration}`);
      });
    } else {
      console.log('\n❌ FAILED: No plans returned or API error');
    }
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
  }
}

// Test with query parameter
async function testPlansAPIWithQuery() {
  const timestamp = Date.now().toString();
  const path = '/subscription/plans?planType=customer';
  const body = '';
  const signature = generateSignature('GET', path, timestamp, body);
  
  console.log('\n\nTesting Plans API with query parameter...');
  console.log(`URL: ${API_BASE}${path}`);
  console.log(`Timestamp: ${timestamp}`);
  console.log(`Body: "${body}"`);
  console.log(`Message: GET|${path}|${timestamp}|${body}`);
  console.log(`Signature: ${signature}`);
  
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
    console.log('\nResponse Status:', response.status);
    console.log('Response Data:', JSON.stringify(data, null, 2));
    
    if (data.success && data.data) {
      console.log(`\n✅ SUCCESS: Found ${data.data.length} customer plans`);
      data.data.forEach((plan, index) => {
        console.log(`${index + 1}. ${plan.name} - $${plan.price}/${plan.duration}`);
      });
    } else {
      console.log('\n❌ FAILED: No customer plans returned or API error');
    }
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
  }
}

// Run tests
testPlansAPI().then(() => testPlansAPIWithQuery());
