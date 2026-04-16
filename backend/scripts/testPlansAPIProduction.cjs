const crypto = require('crypto');
const axios = require('axios');

// Configuration
const API_BASE_URL = 'http://localhost:5005/api/v1';
const API_SIGNING_SECRET = 'convenz_default_secret_key_2024_@!';
const PATH = '/subscription/plans';

console.log('=== PRODUCTION PLANS API TEST ===\n');

// Test 1: Generate signature exactly like frontend
function generateSignature(method, path, timestamp, bodyString) {
  const dataToSign = `${method.toUpperCase()}|${path}|${timestamp}|${bodyString}`;
  console.log(`Data to sign: "${dataToSign}"`);
  
  const hmac = crypto.createHmac('sha256', API_SIGNING_SECRET);
  hmac.update(dataToSign);
  const signature = hmac.digest('hex');
  
  console.log(`Generated signature: ${signature}`);
  return signature;
}

// Test with fresh timestamp
const timestamp = Date.now().toString();
const bodyString = '';

console.log(`Timestamp: ${timestamp}`);
console.log(`Method: GET`);
console.log(`Path: ${PATH}`);
console.log(`Body: "${bodyString}"`);
console.log('');

const signature = generateSignature('GET', PATH, timestamp, bodyString);

// Test the API
async function testPlansAPI() {
  try {
    console.log('=== TESTING PLANS API ===');
    
    const response = await axios.get(`${API_BASE_URL}${PATH}`, {
      headers: {
        'x-timestamp': timestamp,
        'x-signature': signature,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('SUCCESS! Plans API responded:');
    console.log(`Status: ${response.status}`);
    console.log(`Plans count: ${response.data.data?.plans?.length || 0}`);
    console.log('Plans:', JSON.stringify(response.data.data?.plans || [], null, 2));
    
  } catch (error) {
    console.log('ERROR! Plans API failed:');
    if (error.response) {
      console.log(`Status: ${error.response.status}`);
      console.log(`Response: ${JSON.stringify(error.response.data, null, 2)}`);
    } else {
      console.log(`Error: ${error.message}`);
    }
  }
}

// Test the API
testPlansAPI();