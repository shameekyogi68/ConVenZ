import crypto from 'crypto';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const API_SECRET = 'convenz_default_secret_key_2024_@!';

function generateSignature(method, path, timestamp, body = '') {
  const message = `${method}|${path}|${timestamp}|${body}`;
  console.log(`Backend generating signature for: ${message}`);
  const hmac = crypto.createHmac('sha256', API_SECRET);
  const signatureBytes = hmac.update(message).digest();
  const signature = signatureBytes.toString('hex');
  console.log(`Backend signature: ${signature}`);
  return signature;
}

// Test backend signature generation
const timestamp = '1776274044239';
const path = '/subscription/plans?planType=customer';
const body = '';

console.log('=== BACKEND SIGNATURE GENERATION TEST ===');
const backendSignature = generateSignature('GET', path, timestamp, body);

console.log('\n=== FRONTEND SIGNATURE GENERATION TEST ===');
// Simulate frontend signature generation (Dart/JS equivalent)
const message = `GET|${path}|${timestamp}|${body}`;
const hmac = crypto.createHmac('sha256', API_SECRET);
const signatureBytes = hmac.update(message).digest();
const frontendSignature = signatureBytes.map((byte) => byte.toString(16).padStart(2, '0')).join('');

console.log(`Frontend signature: ${frontendSignature}`);
console.log(`Signatures match: ${backendSignature === frontendSignature}`);
console.log(`Backend length: ${backendSignature.length}`);
console.log(`Frontend length: ${frontendSignature.length}`);

if (backendSignature === frontendSignature) {
  console.log('\n✅ SIGNATURES MATCH! API should work.');
} else {
  console.log('\n❌ SIGNATURES MISMATCH! API will fail.');
  console.log(`Backend:  ${backendSignature}`);
  console.log(`Frontend: ${frontendSignature}`);
}
