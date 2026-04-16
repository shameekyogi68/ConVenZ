const crypto = require('crypto');
const axios = require('axios');

const RENDER_URL = 'https://convenz.onrender.com';
const API_SIGNING_SECRET = 'convenz_default_secret_key_2024_@!';

console.log('=============================================');
console.log('🚀 CONVENZ ACCEPTANCE TESTING (PRODUCTION)');
console.log('=============================================\n');

function generateSignature(method, path, timestamp, bodyString) {
  const dataToSign = `${method.toUpperCase()}|${path}|${timestamp}|${bodyString}`;
  const hmac = crypto.createHmac('sha256', API_SIGNING_SECRET);
  hmac.update(dataToSign);
  return hmac.digest('hex');
}

/**
 * Helper to make signed requests 
 */
async function makeSignedRequest(method, endpoint, data = null) {
  const timestamp = Date.now().toString();
  const bodyString = data ? JSON.stringify(data) : '';
  const signature = generateSignature(method, endpoint, timestamp, bodyString);
  
  const headers = {
    'x-timestamp': timestamp,
    'x-signature': signature,
    'Content-Type': 'application/json',
    'User-Agent': 'AcceptanceTesting/1.0'
  };

  try {
    const axiosConfig = {
      method: method,
      url: `${RENDER_URL}${endpoint}`,
      headers: headers
    };
    if (data !== null) {
        axiosConfig.data = data;
    }
    const response = await axios(axiosConfig);
    return { status: response.status, data: response.data, success: true };
  } catch (error) {
    if (error.response) {
      return { status: error.response.status, data: error.response.data, success: false };
    }
    return { status: 500, data: error.message, success: false };
  }
}

async function runTests() {
  let passed = 0;
  let total = 0;

  function assertResult(testName, condition, details = "") {
    total++;
    if (condition) {
      console.log(`✅ PASS: ${testName} ${details}`);
      passed++;
    } else {
      console.log(`❌ FAIL: ${testName} \n   -> Details: ${details}`);
    }
  }

  // 1. Test Health Endpoint
  console.log('--- TEST 1: Server Health ---');
  try {
    const health = await axios.get(`${RENDER_URL}/health`);
    assertResult('Health Check /health', health.status === 200, `- Status: ${health.data.status}, Uptime: ${health.data.uptimeSeconds}s`);
  } catch(e) {
    assertResult('Health Check /health', false, e.message);
  }

  // 2. Test Unsigned Request Rejection
  console.log('\n--- TEST 2: Security Middleware ---');
  try {
    await axios.get(`${RENDER_URL}/api/v1/subscription/plans`);
    assertResult('Reject Unsigned Request', false, "Request succeeded without signature!");
  } catch(e) {
    assertResult('Reject Unsigned Request', e.response && e.response.status === 403, `- Received graceful 403 Forbidden as expected.`);
  }

  // 3. Test Subscription Plans (Signed)
  console.log('\n--- TEST 3: Fetch Active Data ---');
  const plansRes = await makeSignedRequest('GET', '/api/v1/subscription/plans');
  if (!(plansRes.status === 200 && plansRes.data.success)) {
    console.log(plansRes);
  }
  assertResult('Fetch Subscription Plans', plansRes.status === 200 && plansRes.data.success, `- Found ${plansRes.data.data?.plans?.length || 0} plans.`);
  
  // 4. Test User Authentication Boundary (Bad Input Validation)
  // We send a bad phone number to verify app-level validation operates correctly while signature is valid
  console.log('\n--- TEST 4: API Validation Boundary ---');
  const otpRes = await makeSignedRequest('POST', '/api/v1/user/register', { phone: "0000" });
  assertResult('Validate Bad Data Gracefully', otpRes.status === 400, `- Properly rejected invalid phone with 400 Bad Request. Msg: ${otpRes.data?.message}`);

  console.log('\n=============================================');
  console.log(`🏁 TEST SUITE COMPLETE: ${passed}/${total} PASSED`);
  if (passed === total) {
    console.log('🌟 STATUS: FULLY OPERATIONAL. READY FOR RELEASE.');
  } else {
    console.log('⚠️ STATUS: ISSUES DETECTED. DO NOT RELEASE.');
  }
  console.log('=============================================\n');
}

runTests();
