const axios = require('axios');
const crypto = require('crypto');

const RENDER_URL = 'https://convenz.onrender.com';
const API_SIGNING_SECRET = 'convenz_default_secret_key_2024_@!';

function generateSignature(method, path, timestamp, bodyString) {
  const dataToSign = `${method.toUpperCase()}|${path}|${timestamp}|${bodyString}`;
  return crypto.createHmac('sha256', API_SIGNING_SECRET).update(dataToSign).digest('hex');
}

async function run() {
  const method = 'GET';
  const endpoint = '/api/v1/subscription/plans';
  const timestamp = Date.now().toString();
  const signature = generateSignature(method, endpoint, timestamp, '');

  try {
    const res = await axios({
      method,
      url: `${RENDER_URL}${endpoint}`,
      headers: {
        'x-timestamp': timestamp,
        'x-signature': signature,
        'Content-Type': 'application/json'
      }
    });
    console.log("Success:", res.status, res.data);
  } catch (err) {
    if (err.response) {
      console.log("Error status:", err.response.status);
      console.log("Error data:", err.response.data);
      console.log("Error headers:", err.response.headers);
    } else {
      console.log("Error message:", err.message);
    }
  }
}
run();
