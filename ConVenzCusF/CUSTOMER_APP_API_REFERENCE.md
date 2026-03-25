# 🚀 CUSTOMER APP - COMPLETE API REFERENCE

## Base URL
```
https://convenzcusb-backend.onrender.com
```

---

## 📱 **AUTHENTICATION APIs**

### 1. Send OTP
```http
POST /api/auth/send-otp
Content-Type: application/json

{
  "mobile": "9876543210",
  "userType": "customer"
}

Response:
{
  "success": true,
  "message": "OTP sent successfully",
  "userId": "673a1b2c3d4e5f6g7h8i9j0k"
}
```

### 2. Verify OTP
```http
POST /api/auth/verify-otp
Content-Type: application/json

{
  "mobile": "9876543210",
  "otp": "123456",
  "userType": "customer"
}

Response:
{
  "success": true,
  "message": "OTP verified successfully",
  "userId": "673a1b2c3d4e5f6g7h8i9j0k",
  "isNewUser": false
}
```

### 3. Update FCM Token
```http
POST /api/auth/update-fcm-token
Content-Type: application/json

{
  "userId": "673a1b2c3d4e5f6g7h8i9j0k",
  "fcmToken": "fLx3Kj9mN2pQ5rT8vW1yZ4bD7eH0iJ3lM6nP9qS2tU5wX8zA1cE4fG7hI0jK3mN6o",
  "userType": "customer"
}

Response:
{
  "success": true,
  "message": "FCM token updated successfully"
}
```

---

## 📍 **LOCATION APIs**

### 4. Update User Location
```http
POST /api/auth/update-user-location
Content-Type: application/json

{
  "userId": "673a1b2c3d4e5f6g7h8i9j0k",
  "latitude": 19.0760,
  "longitude": 72.8777
}

Response:
{
  "success": true,
  "message": "Location updated successfully",
  "data": {
    "userId": "673a1b2c3d4e5f6g7h8i9j0k",
    "latitude": 19.0760,
    "longitude": 72.8777,
    "address": "Marine Drive, Mumbai, Maharashtra, India"
  }
}
```

---

## 📝 **BOOKING APIs**

### 5. Create Booking ⭐ MAIN ENDPOINT
```http
POST /api/user/booking/create
Content-Type: application/json

{
  "userId": "673a1b2c3d4e5f6g7h8i9j0k",
  "selectedService": "Plumbing",
  "selectedDate": "2025-12-05",
  "selectedTime": "10:30 AM",
  "userLocation": {
    "latitude": 19.0760,
    "longitude": 72.8777,
    "address": "Marine Drive, Mumbai, Maharashtra, India"
  },
  "jobDescription": "Fix kitchen sink leak"
}

Response:
{
  "success": true,
  "message": "Booking created successfully",
  "data": {
    "_id": "674b2c3d4e5f6g7h8i9j0k1l",
    "userId": "673a1b2c3d4e5f6g7h8i9j0k",
    "selectedService": "Plumbing",
    "status": "pending",
    "selectedDate": "2025-12-05",
    "selectedTime": "10:30 AM",
    "userLocation": {
      "latitude": 19.0760,
      "longitude": 72.8777,
      "address": "Marine Drive, Mumbai, Maharashtra, India"
    },
    "jobDescription": "Fix kitchen sink leak",
    "createdAt": "2025-12-04T10:25:30.000Z"
  }
}
```

### 6. Get User Bookings
```http
GET /api/booking/user/{userId}

Response:
{
  "success": true,
  "data": [
    {
      "_id": "674b2c3d4e5f6g7h8i9j0k1l",
      "userId": "673a1b2c3d4e5f6g7h8i9j0k",
      "selectedService": "Plumbing",
      "status": "accepted",
      "vendorId": "675c3d4e5f6g7h8i9j0k1l2m",
      "vendorName": "John Plumber",
      "vendorPhone": "+919876543210",
      "selectedDate": "2025-12-05",
      "selectedTime": "10:30 AM"
    }
  ]
}
```

### 7. Get Single Booking
```http
GET /api/booking/{bookingId}

Response:
{
  "success": true,
  "data": {
    "_id": "674b2c3d4e5f6g7h8i9j0k1l",
    "userId": "673a1b2c3d4e5f6g7h8i9j0k",
    "status": "in_progress",
    "vendorName": "John Plumber",
    "vendorPhone": "+919876543210",
    ...
  }
}
```

### 8. Cancel Booking
```http
POST /api/booking/{bookingId}/cancel
Content-Type: application/json

{}

Response:
{
  "success": true,
  "message": "Booking cancelled successfully"
}
```

---

## 👤 **PROFILE APIs**

### 9. Get User Profile
```http
GET /api/auth/profile/{userId}

Response:
{
  "success": true,
  "data": {
    "userId": "673a1b2c3d4e5f6g7h8i9j0k",
    "mobile": "9876543210",
    "name": "Ramesh Kumar",
    "email": "ramesh@example.com",
    "address": "Marine Drive, Mumbai",
    "latitude": 19.0760,
    "longitude": 72.8777
  }
}
```

### 10. Update User Profile
```http
POST /api/auth/update-profile
Content-Type: application/json

{
  "userId": "673a1b2c3d4e5f6g7h8i9j0k",
  "name": "Ramesh Kumar",
  "email": "ramesh@example.com",
  "address": "Marine Drive, Mumbai"
}

Response:
{
  "success": true,
  "message": "Profile updated successfully"
}
```

---

## 🔔 **FCM NOTIFICATION TYPES** (Server → Customer)

### Notification 1: OTP Delivery
```json
{
  "notification": {
    "title": "Your OTP Code",
    "body": "Your OTP is 123456"
  },
  "data": {
    "type": "OTP",
    "otp": "123456",
    "userId": "673a1b2c3d4e5f6g7h8i9j0k"
  }
}
```

### Notification 2: Vendor Assigned
```json
{
  "notification": {
    "title": "Vendor Assigned!",
    "body": "John Plumber will arrive at 10:30 AM"
  },
  "data": {
    "type": "VENDOR_ASSIGNED",
    "bookingId": "674b2c3d4e5f6g7h8i9j0k1l",
    "vendorName": "John Plumber",
    "vendorPhone": "+919876543210"
  }
}
```

### Notification 3: Booking Status Update
```json
{
  "notification": {
    "title": "Booking Update",
    "body": "Your booking is now in progress"
  },
  "data": {
    "type": "BOOKING_STATUS_UPDATE",
    "bookingId": "674b2c3d4e5f6g7h8i9j0k1l",
    "status": "in_progress"
  }
}
```

---

## ⚡ **ERROR HANDLING**

All API responses follow this structure:

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

### Common HTTP Status Codes
- `200` - Success
- `400` - Bad Request (validation error)
- `401` - Unauthorized (invalid token)
- `404` - Not Found
- `500` - Server Error
- `504` - Gateway Timeout (Render.com cold start)

---

## 🔄 **REAL-TIME UPDATES FLOW**

```
1. Customer creates booking
   POST /api/user/booking/create
   
2. Backend finds nearby vendor
   - Geospatial query on vendor locations
   - Filter by selectedServices array
   
3. Backend sends FCM to Vendor
   - Notification type: NEW_BOOKING
   
4. Vendor accepts booking
   - Backend updates booking status
   
5. Backend sends FCM to Customer
   - Notification type: VENDOR_ASSIGNED
   
6. Customer app polls for updates
   - GET /api/booking/{bookingId} every 3 seconds
   - Stops when status = completed/cancelled
   
7. Status changes trigger FCM
   - accepted → in_progress → completed
   - Each change sends BOOKING_STATUS_UPDATE
```

---

## 📊 **BOOKING STATUS FLOW**

```
pending → accepted → in_progress → completed
   ↓
cancelled (can happen at any stage)
   ↓
rejected (vendor declines)
```

---

## 🛠️ **RETRY LOGIC**

Implemented in `lib/services/booking_service.dart`:

```dart
// Auto-retry with exponential backoff
try {
  final res = await ApiService.post("/user/booking/create", data);
  if (res['success'] != true) {
    // Retry after 2 seconds
    await Future.delayed(Duration(seconds: 2));
    final retry = await ApiService.post("/user/booking/create", data);
    return retry;
  }
  return res;
} catch (e) {
  return {"success": false, "message": "Network error: $e"};
}
```

---

## 🔐 **SECURITY CONSIDERATIONS**

1. **No JWT tokens** - Using userId from SharedPreferences
2. **FCM token rotation** - Update on every app launch
3. **Location privacy** - Only sent when creating booking
4. **OTP expiry** - Backend enforces 5-minute expiry
5. **Rate limiting** - Backend limits OTP requests per phone

---

## 📦 **DEPENDENCIES**

```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^17.2.3
  http: ^1.2.0
  shared_preferences: ^2.2.2
  geolocator: ^11.0.0
  flutter_map: ^6.0.0
  url_launcher: ^6.3.2
  intl: ^0.19.0
```
