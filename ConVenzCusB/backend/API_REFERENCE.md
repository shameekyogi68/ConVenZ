# 🚀 Customer Backend - Quick API Reference

## Base URL
```
https://convenzcusb-backend.onrender.com
```

---

## 📋 All Endpoints

### 🔐 Authentication
```bash
# 1. Register / Generate OTP
POST /api/user/register
Body: { "phone": 9876543210, "fcmToken": "..." }

# 2. Verify OTP
POST /api/user/verify-otp
Body: { "phone": 9876543210, "otp": 1234 }
```

### 👤 User Management
```bash
# 3. Update User Details
POST /api/user/update-user
Body: { "phone": 9876543210, "name": "John", "gender": "Male" }

# 4. Update Location
POST /api/user/update-location
Body: { "userId": 1, "latitude": 12.9716, "longitude": 77.5946, "address": "Bangalore" }

# 5. Update FCM Token
POST /api/user/update-fcm-token
Body: { "userId": 1, "fcmToken": "new-token" }

# 6. Get User Profile
GET /api/user/profile/:userId

# 7. Update User Profile
POST /api/user/profile/:userId
Body: { "name": "John", "phone": 9876543210, "address": "..." }
```

### 📅 Booking Management
```bash
# 8. Create Booking (Forwards to Vendor Backend)
POST /api/user/booking/create
Body: {
  "userId": 1,
  "selectedService": "Plumbing",
  "jobDescription": "Fix sink",
  "date": "2025-12-10",
  "time": "10:00 AM",
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946,
    "address": "Bangalore"
  }
}

# 9. Get User Bookings
GET /api/user/bookings/:userId

# 10. Get Single Booking
GET /api/user/booking/:bookingId

# 11. Cancel Booking
POST /api/user/booking/:bookingId/cancel
Body: { "userId": 1 }

# 12. Update Booking Status (Called by Vendor Backend)
POST /api/user/booking/status-update
Body: {
  "bookingId": 1,
  "status": "accepted",
  "vendorId": 5,
  "otpStart": 1234
}
```

---

## 🔄 Server-to-Server Flows

### Flow 1: Customer Creates Booking
```
Customer App
    ↓ POST /api/user/booking/create
Customer Backend
    ↓ Finds vendor & POSTs to:
Vendor Backend: POST /vendor/api/new-booking
    ↓ Sends FCM to vendor app
Vendor App (receives notification)
```

### Flow 2: Vendor Updates Status
```
Vendor App (Accept/Reject)
    ↓ Sends to vendor backend
Vendor Backend
    ↓ POST /api/user/booking/status-update
Customer Backend
    ↓ Updates DB & sends FCM
Customer App (receives notification)
```

---

## 📦 Request/Response Examples

### Create Booking Request
```json
{
  "userId": 1,
  "selectedService": "Plumbing",
  "jobDescription": "Kitchen sink leaking",
  "date": "2025-12-10",
  "time": "10:00 AM",
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946,
    "address": "123 Main St, Bangalore"
  }
}
```

### Create Booking Response
```json
{
  "success": true,
  "message": "Booking created and vendor notified",
  "data": {
    "bookingId": 1,
    "status": "pending",
    "service": "Plumbing",
    "date": "2025-12-10",
    "time": "10:00 AM",
    "location": "123 Main St, Bangalore",
    "vendor": {
      "id": 5,
      "name": "Ram Kumar",
      "distance": "2.5 km"
    }
  }
}
```

### Status Update Request (from Vendor Backend)
```json
{
  "bookingId": 1,
  "status": "accepted",
  "vendorId": 5,
  "otpStart": 1234
}
```

### Status Update Response
```json
{
  "success": true,
  "message": "Booking status updated successfully",
  "data": {
    "bookingId": 1,
    "status": "accepted",
    "otpStart": 1234,
    "vendorId": 5
  }
}
```

---

## 🔔 FCM Notifications Sent

### 1. OTP Delivery
```
Title: "Your OTP Code"
Body: "Your verification code is: 1234"
Data: { type: "OTP", otp: "1234" }
```

### 2. Booking Confirmation
```
Title: "✅ Booking Confirmed"
Body: "Your Plumbing request has been sent to a vendor"
Data: { type: "BOOKING_CONFIRMATION", bookingId: "1" }
```

### 3. Booking Accepted
```
Title: "✅ Booking Accepted!"
Body: "Your booking has been accepted. OTP: 1234"
Data: { type: "BOOKING_STATUS_UPDATE", status: "accepted", otp: "1234" }
```

### 4. Booking Rejected
```
Title: "❌ Booking Rejected"
Body: "Sorry, your booking was rejected. Finding another vendor."
Data: { type: "BOOKING_STATUS_UPDATE", status: "rejected" }
```

### 5. Service Completed
```
Title: "🎉 Service Completed"
Body: "Your Plumbing service has been completed. Thank you!"
Data: { type: "BOOKING_STATUS_UPDATE", status: "completed" }
```

---

## 🎯 Valid Booking Statuses

- `pending` - Initial status after creation
- `accepted` - Vendor accepted (OTP generated)
- `rejected` - Vendor rejected
- `completed` - Service finished
- `cancelled` - Booking cancelled by customer/vendor

---

## 🔒 Environment Variables Required

```env
PORT=5005
MONGODB_URI=mongodb+srv://...
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
VENDOR_BACKEND_URL=https://vendor-backend-7cn3.onrender.com
```

---

## 🧪 Quick Test Commands

```bash
# Test health check
curl https://convenzcusb-backend.onrender.com/

# Generate OTP
curl -X POST https://convenzcusb-backend.onrender.com/api/user/register \
  -H "Content-Type: application/json" \
  -d '{"phone": 9876543210}'

# Create booking
curl -X POST https://convenzcusb-backend.onrender.com/api/user/booking/create \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "selectedService": "Plumbing",
    "jobDescription": "Fix sink",
    "date": "2025-12-10",
    "time": "10:00 AM",
    "location": {
      "latitude": 12.9716,
      "longitude": 77.5946,
      "address": "Bangalore"
    }
  }'

# Update booking status (vendor backend calls this)
curl -X POST https://convenzcusb-backend.onrender.com/api/user/booking/status-update \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": 1,
    "status": "accepted",
    "vendorId": 5,
    "otpStart": 1234
  }'
```

---

## ✅ Implementation Status

| Feature | Status |
|---------|--------|
| OTP Login | ✅ |
| FCM Token Management | ✅ |
| User Profiles | ✅ |
| Create Bookings | ✅ |
| Forward to Vendor Backend | ✅ |
| Receive Status Updates | ✅ |
| Customer Notifications | ✅ |
| Vendor Matching | ✅ |
| Distance Calculation | ✅ |

**All features implemented. Zero errors. Production ready.**
