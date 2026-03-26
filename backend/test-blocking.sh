#!/bin/bash

echo "🧪 Testing User Blocking Functionality"
echo "=========================================="
echo ""

BASE_URL="https://convenzcusb-backend.onrender.com"
USER_ID=15

# Test 1: Check current block status
echo "1️⃣  Checking current block status for user $USER_ID..."
curl -s "$BASE_URL/api/user/admin/check-status/$USER_ID" | jq '.'
echo ""

# Test 2: Block the user
echo "2️⃣  Blocking user $USER_ID..."
BLOCK_RESPONSE=$(curl -s -X POST "$BASE_URL/api/user/admin/block-user" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": $USER_ID,
    \"blockReason\": \"Testing blocking functionality - automated test\"
  }")
echo "$BLOCK_RESPONSE" | jq '.'
echo ""

# Test 3: Try to create booking as blocked user
echo "3️⃣  Attempting to create booking as blocked user..."
BOOKING_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/api/user/booking/create" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": $USER_ID,
    \"selectedService\": \"Plumbing\",
    \"jobDescription\": \"Test booking while blocked\",
    \"date\": \"2025-12-10\",
    \"time\": \"10:00 AM\",
    \"location\": {
      \"latitude\": 12.9716,
      \"longitude\": 77.5946,
      \"address\": \"Test Address\"
    }
  }")

HTTP_CODE=$(echo "$BOOKING_RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
RESPONSE=$(echo "$BOOKING_RESPONSE" | sed '/HTTP_CODE:/d')

echo "$RESPONSE" | jq '.'
echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "403" ]; then
  echo "✅ SUCCESS! Blocked user cannot create booking (403 returned)"
else
  echo "❌ FAILED! Expected 403 but got $HTTP_CODE"
fi
echo ""

# Test 4: Try to update profile as blocked user
echo "4️⃣  Attempting to update profile as blocked user..."
PROFILE_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/api/user/update-user" \
  -H "Content-Type: application/json" \
  -d "{
    \"phone\": 9085214796,
    \"name\": \"Updated Name\",
    \"gender\": \"Male\"
  }")

HTTP_CODE=$(echo "$PROFILE_RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
RESPONSE=$(echo "$PROFILE_RESPONSE" | sed '/HTTP_CODE:/d')

echo "$RESPONSE" | jq '.'
echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "403" ]; then
  echo "✅ SUCCESS! Blocked user cannot update profile (403 returned)"
else
  echo "❌ FAILED! Expected 403 but got $HTTP_CODE"
fi
echo ""

# Test 5: Unblock the user
echo "5️⃣  Unblocking user $USER_ID..."
UNBLOCK_RESPONSE=$(curl -s -X POST "$BASE_URL/api/user/admin/unblock-user" \
  -H "Content-Type: application/json" \
  -d "{\"userId\": $USER_ID}")
echo "$UNBLOCK_RESPONSE" | jq '.'
echo ""

# Test 6: Try booking again after unblock
echo "6️⃣  Attempting to create booking after unblock..."
BOOKING_RESPONSE2=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL/api/user/booking/create" \
  -H "Content-Type: application/json" \
  -d "{
    \"userId\": $USER_ID,
    \"selectedService\": \"Plumbing\",
    \"jobDescription\": \"Test booking after unblock\",
    \"date\": \"2025-12-10\",
    \"time\": \"10:00 AM\",
    \"location\": {
      \"latitude\": 12.9716,
      \"longitude\": 77.5946,
      \"address\": \"Test Address\"
    }
  }")

HTTP_CODE=$(echo "$BOOKING_RESPONSE2" | grep "HTTP_CODE:" | cut -d':' -f2)
RESPONSE=$(echo "$BOOKING_RESPONSE2" | sed '/HTTP_CODE:/d')

echo "$RESPONSE" | jq '.'
echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
  echo "✅ SUCCESS! Unblocked user can create booking"
else
  echo "⚠️  Note: HTTP $HTTP_CODE - Check if user exists and vendor is available"
fi
echo ""

echo "=========================================="
echo "✅ Blocking functionality tests completed!"
