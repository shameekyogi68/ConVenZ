#!/bin/bash

echo "🧪 Testing Customer Booking Endpoint"
echo "======================================"
echo ""

# Test 1: Health Check
echo "1️⃣  Testing Health Check..."
HEALTH=$(curl -s https://convenzcusb-backend.onrender.com/)
echo "$HEALTH" | jq '.'
echo ""

# Test 2: Create Booking
echo "2️⃣  Testing Booking Creation..."
echo "   URL: https://convenzcusb-backend.onrender.com/api/user/booking/create"
echo ""

BOOKING_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST https://convenzcusb-backend.onrender.com/api/user/booking/create \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "selectedService": "Plumbing",
    "jobDescription": "Kitchen sink is leaking badly",
    "date": "2025-12-10",
    "time": "10:00 AM",
    "location": {
      "latitude": 12.9716,
      "longitude": 77.5946,
      "address": "123 Main Street, Bangalore, Karnataka"
    }
  }')

# Extract HTTP code
HTTP_CODE=$(echo "$BOOKING_RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
RESPONSE=$(echo "$BOOKING_RESPONSE" | sed '/HTTP_CODE:/d')

echo "Response:"
echo "$RESPONSE" | jq '.'
echo ""
echo "HTTP Status Code: $HTTP_CODE"
echo ""

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ SUCCESS! Booking endpoint is working"
else
  echo "❌ FAILED! HTTP Code: $HTTP_CODE"
  echo ""
  echo "Troubleshooting:"
  echo "1. Check if server is running: https://convenzcusb-backend.onrender.com/"
  echo "2. Verify route is mounted: POST /api/user/booking/create"
  echo "3. Check Render logs for errors"
fi

echo ""
echo "======================================"
