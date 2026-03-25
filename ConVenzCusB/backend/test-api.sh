#!/bin/bash

# 🧪 Customer Backend API Test Script
# Run this to test all endpoints

BASE_URL="http://localhost:5005"

echo "🚀 Starting Customer Backend API Tests"
echo "========================================"
echo ""

# Test 1: Health Check
echo "1️⃣  Testing Health Check..."
curl -s "$BASE_URL/" | jq '.'
echo ""

# Test 2: Register User (Get OTP)
echo "2️⃣  Testing User Registration (OTP Generation)..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/user/register" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": 9876543210,
    "fcmToken": "test-fcm-token-123"
  }')
echo "$REGISTER_RESPONSE" | jq '.'
OTP=$(echo "$REGISTER_RESPONSE" | jq -r '.otp')
USER_ID=$(echo "$REGISTER_RESPONSE" | jq -r '.userId')
echo "📝 OTP: $OTP"
echo "👤 User ID: $USER_ID"
echo ""

# Test 3: Verify OTP
echo "3️⃣  Testing OTP Verification..."
curl -s -X POST "$BASE_URL/api/user/verify-otp" \
  -H "Content-Type: application/json" \
  -d "{
    \"phone\": 9876543210,
    \"otp\": $OTP
  }" | jq '.'
echo ""

# Test 4: Update User Details
echo "4️⃣  Testing Update User Details..."
curl -s -X POST "$BASE_URL/api/user/update-user" \
  -H "Content-Type: application/json" \
  -d '{
    "phone": 9876543210,
    "name": "Test Customer",
    "gender": "Male"
  }' | jq '.'
echo ""

# Test 5: Update Location
echo "5️⃣  Testing Update Location..."
curl -s -X POST "$BASE_URL/api/user/update-location" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": $USER_ID,
    \"latitude\": 12.9716,
    \"longitude\": 77.5946,
    \"address\": \"Bangalore, Karnataka\"
  }" | jq '.'
echo ""

# Test 6: Update FCM Token
echo "6️⃣  Testing Update FCM Token..."
curl -s -X POST "$BASE_URL/api/user/update-fcm-token" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": $USER_ID,
    \"fcmToken\": \"updated-fcm-token-456\"
  }" | jq '.'
echo ""

# Test 7: Create Booking
echo "7️⃣  Testing Booking Creation..."
BOOKING_RESPONSE=$(curl -s -X POST "$BASE_URL/api/user/booking/create" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": $USER_ID,
    \"selectedService\": \"Plumbing\",
    \"jobDescription\": \"Kitchen sink is leaking badly\",
    \"date\": \"2025-12-10\",
    \"time\": \"10:00 AM\",
    \"location\": {
      \"latitude\": 12.9716,
      \"longitude\": 77.5946,
      \"address\": \"123 Main Street, Bangalore, Karnataka\"
    }
  }")
echo "$BOOKING_RESPONSE" | jq '.'
BOOKING_ID=$(echo "$BOOKING_RESPONSE" | jq -r '.data.bookingId')
echo "📅 Booking ID: $BOOKING_ID"
echo ""

# Test 8: Get User Bookings
echo "8️⃣  Testing Get User Bookings..."
curl -s "$BASE_URL/api/user/bookings/$USER_ID" | jq '.'
echo ""

# Test 9: Get Single Booking Details
if [ "$BOOKING_ID" != "null" ]; then
  echo "9️⃣  Testing Get Booking Details..."
  curl -s "$BASE_URL/api/user/booking/$BOOKING_ID" | jq '.'
  echo ""
fi

# Test 10: Get User Profile
echo "🔟 Testing Get User Profile..."
curl -s "$BASE_URL/api/user/profile/$USER_ID" | jq '.'
echo ""

echo "========================================"
echo "✅ All API tests completed!"
echo ""
echo "📝 Summary:"
echo "   - User ID: $USER_ID"
echo "   - OTP: $OTP"
echo "   - Booking ID: $BOOKING_ID"
echo ""
echo "🎯 Next Steps:"
echo "   1. Configure VENDOR_BACKEND_URL in .env"
echo "   2. Test vendor backend endpoint: POST /vendor/api/new-booking"
echo "   3. Deploy to Render"
echo ""
