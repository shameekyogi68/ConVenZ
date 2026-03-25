# 📱 Flutter Frontend Integration Guide

## ✅ ALL ISSUES FIXED

### 1. ✅ Route 404 Errors - SOLVED
**Problem**: Flutter app calling `/api/user/user/register` was getting 404  
**Solution**: Backend now supports BOTH endpoint formats:
- ✅ `/api/user/register` (correct)
- ✅ `/api/user/user/register` (your current Flutter path)

**No Flutter changes needed!** Your app will work as-is.

---

### 2. ✅ User Blocking System - WORKING PERFECTLY

**How it works:**
1. **Any user** can enter phone number and get OTP (even blocked users)
2. **Only blocked users** get error when verifying OTP
3. **New users** and **active users** can login flawlessly

**Example Flow:**
```
User ID 15 (blocked):
1. Enters phone → ✅ Gets OTP
2. Enters OTP → ❌ 403 Error: "Your account has been blocked"

New user:
1. Enters phone → ✅ Gets OTP
2. Enters OTP → ✅ Login successful

Existing active user:
1. Enters phone → ✅ Gets OTP
2. Enters OTP → ✅ Login successful
```

---

## 🔌 Backend Endpoints (All Working)

**Base URL**: `https://convenzcusb-backend.onrender.com`

### Authentication Endpoints

#### 1️⃣ Register / Get OTP
```
POST /api/user/register
OR
POST /api/user/user/register  ← Your Flutter path works too!

Body:
{
  "phone": "9876543210",
  "fcmToken": "firebase_token_here"  // Optional
}

Response (Success):
{
  "success": true,
  "message": "OTP sent successfully",
  "otp": 1234,
  "userId": 1,
  "isNewUser": true
}
```

#### 2️⃣ Verify OTP / Login
```
POST /api/user/verify-otp
OR
POST /api/user/user/verify-otp  ← Your Flutter path works too!

Body:
{
  "phone": "9876543210",
  "otp": 1234
}

Response (Success):
{
  "success": true,
  "message": "OTP verified",
  "userId": 1,
  "isNewUser": false,
  "user": {
    "user_id": 1,
    "phone": "9876543210",
    "name": "John Doe",
    "email": "john@example.com",
    "gender": "Male",
    "fcmToken": "...",
    "isBlocked": false  ← Check this!
  }
}

Response (Blocked User):
{
  "success": false,
  "message": "Your account has been blocked by admin. Please contact support.",
  "blocked": true,
  "blockReason": "Account suspended by admin",
  "supportContact": "Contact admin for assistance"
}
```

---

### Booking Endpoints

#### 3️⃣ Create Booking
```
POST /api/user/booking/create

Body:
{
  "userId": 1,
  "serviceType": "Party Hall Booking",
  "bookingDate": "2024-12-25",
  "bookingTime": "18:00",
  "numberOfGuests": 100,
  "hallType": "AC Hall",
  "additionalServices": ["Catering", "Decoration"],
  "specialRequests": "Need stage setup",
  "customerLocation": {
    "type": "Point",
    "coordinates": [77.5946, 12.9716],  // [longitude, latitude]
    "address": "123 MG Road, Bangalore"
  }
}

Response (Success):
{
  "success": true,
  "message": "Booking created and vendor notified successfully",
  "booking": {
    "booking_id": 1,
    "customerId": 1,
    "status": "pending",
    "serviceType": "Party Hall Booking",
    "bookingDate": "2024-12-25T18:00:00.000Z",
    ...
  },
  "vendorNotification": {
    "fcmSent": true,
    "backendNotified": true,
    "vendorResponse": "Vendor notified"
  }
}

Response (Blocked User):
{
  "success": false,
  "message": "Your account has been blocked by admin. Please contact support.",
  "blocked": true,
  "blockReason": "Account suspended by admin"
}
```

#### 4️⃣ Get User Bookings
```
GET /api/user/bookings/:userId

Example: GET /api/user/bookings/1

Response:
{
  "success": true,
  "bookings": [
    {
      "booking_id": 1,
      "customerId": 1,
      "status": "pending",
      "serviceType": "Party Hall Booking",
      ...
    }
  ]
}
```

#### 5️⃣ Get Single Booking Details
```
GET /api/user/booking/:bookingId

Example: GET /api/user/booking/1

Response:
{
  "success": true,
  "booking": {
    "booking_id": 1,
    "customerId": 1,
    "status": "confirmed",
    ...
  }
}
```

#### 6️⃣ Cancel Booking
```
POST /api/user/booking/:bookingId/cancel

Body:
{
  "userId": 1,
  "cancellationReason": "Plans changed"
}

Response:
{
  "success": true,
  "message": "Booking cancelled successfully",
  "booking": { ... }
}
```

---

### Profile Endpoints

#### 7️⃣ Get User Profile
```
GET /api/user/profile/:userId

Example: GET /api/user/profile/1

Response:
{
  "success": true,
  "user": {
    "user_id": 1,
    "phone": "9876543210",
    "name": "John Doe",
    "email": "john@example.com",
    "gender": "Male",
    "isBlocked": false  ← Always check this
  }
}
```

#### 8️⃣ Update User Profile
```
POST /api/user/profile/:userId

Body:
{
  "userId": 1,
  "name": "John Doe Updated",
  "email": "newemail@example.com",
  "gender": "Male"
}

Response:
{
  "success": true,
  "message": "Profile updated successfully",
  "user": { ... }
}
```

#### 9️⃣ Update FCM Token
```
POST /api/user/update-fcm-token

Body:
{
  "userId": 1,
  "fcmToken": "new_firebase_token_here"
}

Response:
{
  "success": true,
  "message": "FCM token updated"
}
```

---

## 🚨 Flutter Error Handling

### Handle Blocked Users
```dart
// After OTP verification
Future<void> verifyOtp(String phone, String otp) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/user/verify-otp'),
    body: jsonEncode({'phone': phone, 'otp': otp}),
    headers: {'Content-Type': 'application/json'},
  );
  
  final data = jsonDecode(response.body);
  
  if (data['success']) {
    // Login successful
    final user = data['user'];
    
    // IMPORTANT: Check if user is blocked
    if (user['isBlocked'] == true) {
      // Show blocking error (shouldn't reach here but good to check)
      showErrorDialog('Account Blocked', user['blockReason'] ?? 'Your account is suspended');
      return;
    }
    
    // Proceed with login
    navigateToHome(user);
  } else {
    // Check if it's a blocking error
    if (data['blocked'] == true) {
      // User is blocked - show specific message
      showBlockedDialog(
        reason: data['blockReason'] ?? 'Account suspended',
        support: data['supportContact'] ?? 'Contact admin'
      );
    } else {
      // Other errors (invalid OTP, expired, etc.)
      showErrorDialog('Error', data['message']);
    }
  }
}
```

### Handle Blocked Users During Actions
```dart
// When creating booking, updating profile, etc.
Future<void> createBooking(Map<String, dynamic> bookingData) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/user/booking/create'),
    body: jsonEncode(bookingData),
    headers: {'Content-Type': 'application/json'},
  );
  
  final data = jsonDecode(response.body);
  
  if (response.statusCode == 403) {
    // User is blocked
    showBlockedDialog(
      reason: data['blockReason'] ?? 'Account suspended',
      support: data['supportContact'] ?? 'Contact admin'
    );
    // Force logout
    logoutUser();
    return;
  }
  
  if (data['success']) {
    // Booking created successfully
    showSuccessDialog('Booking confirmed!');
  } else {
    showErrorDialog('Error', data['message']);
  }
}
```

---

## 📋 Flutter Checklist

### ✅ What's Already Working
- [x] Phone number input and OTP generation
- [x] Both `/api/user/register` and `/api/user/user/register` work
- [x] Blocked users can't login (get 403 during OTP verification)
- [x] New users can register flawlessly
- [x] Existing active users can login flawlessly
- [x] Booking creation notifies vendor via FCM + backend POST
- [x] Route ordering fixed (no more GET /booking/create errors)

### 🔧 What to Add in Flutter

1. **Handle 403 Status Code**
   - When status code is 403, user is blocked
   - Show dialog with block reason
   - Force logout

2. **Check `isBlocked` Field**
   - After login, check `user.isBlocked`
   - Store in local state
   - Prevent any actions if blocked

3. **Show User-Friendly Messages**
   - For blocked users: "Your account has been suspended. Contact support."
   - For OTP errors: "Invalid OTP" or "OTP expired"
   - For success: "Login successful!"

4. **Auto-Logout on Block**
   - If any API returns 403, immediately logout
   - Clear all local data
   - Redirect to login screen

---

## 🎯 Testing Scenarios

### Scenario 1: New User Registration
```
1. Enter phone: 9999999999
2. Receive OTP in Flutter
3. Enter OTP
4. ✅ Login successful (isNewUser: true)
5. Complete profile
6. ✅ Can create bookings
```

### Scenario 2: Existing Active User
```
1. Enter phone: 9876543210
2. Receive OTP
3. Enter OTP
4. ✅ Login successful (isNewUser: false)
5. ✅ Can access all features
```

### Scenario 3: Blocked User (e.g., User ID 15)
```
1. Enter phone: 9085214796 (User 15 - blocked)
2. ✅ Receive OTP (allowed)
3. Enter OTP
4. ❌ 403 Error: "Your account has been blocked by admin"
5. Flutter shows: "Account Blocked" dialog
6. User cannot login
```

### Scenario 4: User Gets Blocked While Logged In
```
1. User 15 is logged in
2. Admin blocks User 15
3. User 15 tries to create booking
4. ❌ 403 Error: "Your account has been blocked"
5. Flutter force logout
6. Show "Your account was suspended"
```

---

## 🔥 Key Points

1. **No Flutter Changes Required for Route 404** - Backend now handles both paths!

2. **Blocking Works Perfectly**:
   - Registration: ✅ Everyone can get OTP
   - Login: ❌ Blocked users get 403
   - Actions: ❌ Blocked users get 403

3. **Error Handling is Critical**:
   - Always check `response.statusCode == 403`
   - Always check `data['blocked'] == true`
   - Always check `user['isBlocked']` field

4. **User Experience**:
   - New users: Seamless registration
   - Active users: Seamless login
   - Blocked users: Clear error message + cannot proceed

---

## 💡 Recommended Flutter Structure

```dart
class ApiService {
  static const String baseUrl = 'https://convenzcusb-backend.onrender.com';
  
  // Check if response indicates user is blocked
  static bool isUserBlocked(dynamic responseData, int statusCode) {
    return statusCode == 403 || responseData['blocked'] == true;
  }
  
  // Handle blocked user
  static void handleBlockedUser(BuildContext context, dynamic responseData) {
    final reason = responseData['blockReason'] ?? 'Your account is suspended';
    final support = responseData['supportContact'] ?? 'Contact admin for assistance';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Account Blocked'),
        content: Text('$reason\n\n$support'),
        actions: [
          TextButton(
            onPressed: () {
              // Logout and go to login screen
              logout(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎉 Summary

**Everything is working!** Your backend:
- ✅ Accepts both endpoint formats (no Flutter changes needed)
- ✅ Allows all users to register/get OTP
- ✅ Blocks only blocked users during login
- ✅ Blocks blocked users from all actions
- ✅ Notifies vendors perfectly (FCM + backend POST)
- ✅ No more 404 errors
- ✅ No more route matching errors

**Your Flutter app should work flawlessly** - just add proper error handling for blocked users! 🚀
