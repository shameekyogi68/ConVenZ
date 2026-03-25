# 📱 Flutter App Integration Guide

## ✅ Correct Booking Endpoint

### Base URL
```
https://convenzcusb-backend.onrender.com
```

### Booking Creation Endpoint
```
POST https://convenzcusb-backend.onrender.com/api/user/booking/create
```

---

## 📋 Flutter Code Example

### 1. API Service Class

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class CustomerApiService {
  static const String baseUrl = 'https://convenzcusb-backend.onrender.com';
  
  // Create Booking
  static Future<Map<String, dynamic>> createBooking({
    required int userId,
    required String selectedService,
    required String jobDescription,
    required String date,
    required String time,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      print('📤 Creating booking...');
      print('URL: $baseUrl/api/user/booking/create');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/user/booking/create'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'selectedService': selectedService,
          'jobDescription': jobDescription,
          'date': date,
          'time': time,
          'location': {
            'latitude': latitude,
            'longitude': longitude,
            'address': address,
          },
        }),
      );
      
      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Booking created successfully!');
        return data;
      } else {
        print('❌ Failed to create booking: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Failed to create booking: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating booking: $e');
      rethrow;
    }
  }
}
```

---

## 🔧 Complete Booking Flow in Flutter

```dart
import 'package:flutter/material.dart';

class BookingScreen extends StatefulWidget {
  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool isLoading = false;
  
  Future<void> createBooking() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get user data from your state management
      final userId = 1; // Replace with actual user ID
      final selectedService = 'Plumbing'; // From your service selection
      final jobDescription = 'Kitchen sink is leaking';
      final date = '2025-12-10';
      final time = '10:00 AM';
      final latitude = 12.9716; // From location picker
      final longitude = 77.5946;
      final address = '123 Main Street, Bangalore';
      
      print('🚀 Starting booking creation...');
      
      final result = await CustomerApiService.createBooking(
        userId: userId,
        selectedService: selectedService,
        jobDescription: jobDescription,
        date: date,
        time: time,
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
      
      print('✅ Booking result: $result');
      
      // Show success message
      if (result['success'] == true) {
        final bookingId = result['data']['bookingId'];
        final vendorName = result['data']['vendor']?['name'] ?? 'a vendor';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Booking created! Sent to $vendorName'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to booking details or home
        Navigator.pop(context);
      }
      
    } catch (e) {
      print('❌ Error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to create booking. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Service')),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: createBooking,
                child: Text('Book Now'),
              ),
      ),
    );
  }
}
```

---

## 🔍 Common Issues & Solutions

### Issue 1: 404 Not Found

**Possible Causes:**
1. ❌ Wrong URL: `POST /booking/create` (missing `/api/user`)
2. ❌ Wrong URL: `POST /api/booking/create` (missing `user`)
3. ❌ Wrong base URL

**Solution:**
✅ Use: `POST https://convenzcusb-backend.onrender.com/api/user/booking/create`

---

### Issue 2: 400 Bad Request

**Possible Causes:**
1. Missing required fields
2. Invalid location data
3. Wrong data types

**Solution:**
Ensure your request body has:
```dart
{
  "userId": 1,                    // int, required
  "selectedService": "Plumbing",  // string, required
  "jobDescription": "...",        // string, required
  "date": "2025-12-10",          // string, required
  "time": "10:00 AM",            // string, required
  "location": {                   // object, required
    "latitude": 12.9716,         // double, required
    "longitude": 77.5946,        // double, required
    "address": "..."             // string, required
  }
}
```

---

### Issue 3: No Vendor Notification

**Backend automatically handles:**
1. ✅ Finds best available vendor
2. ✅ Sends POST to vendor backend
3. ✅ Sends FCM to vendor app
4. ✅ Sends confirmation FCM to customer

**If vendor doesn't receive:**
1. Check vendor has FCM token registered
2. Verify vendor is online in `vendorpresences` collection
3. Check vendor offers the selected service
4. Ensure vendor is within 50km radius

---

## 🔔 FCM Notification Handling

### Listen for Booking Confirmations

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permission
    await _fcm.requestPermission();
    
    // Get FCM token
    String? token = await _fcm.getToken();
    print('📱 FCM Token: $token');
    
    // Update token on backend
    if (token != null) {
      await updateFcmToken(token);
    }
    
    // Listen for messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Notification received!');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      
      if (message.data['type'] == 'BOOKING_CONFIRMATION') {
        // Show in-app notification
        showBookingConfirmationDialog(message);
      } else if (message.data['type'] == 'BOOKING_STATUS_UPDATE') {
        // Handle status update
        handleBookingStatusUpdate(message);
      }
    });
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 Notification tapped!');
      
      if (message.data['bookingId'] != null) {
        // Navigate to booking details
        navigateToBookingDetails(message.data['bookingId']);
      }
    });
  }
  
  void showBookingConfirmationDialog(RemoteMessage message) {
    // Show dialog or snackbar
    print('✅ Booking confirmed!');
  }
  
  void handleBookingStatusUpdate(RemoteMessage message) {
    final status = message.data['status'];
    
    if (status == 'accepted') {
      final otp = message.data['otp'];
      print('✅ Booking accepted! OTP: $otp');
      // Show OTP to user
    } else if (status == 'rejected') {
      print('❌ Booking rejected');
      // Show rejection message
    }
  }
  
  void navigateToBookingDetails(String bookingId) {
    // Navigate to booking details page
  }
  
  Future<void> updateFcmToken(String token) async {
    // Call your backend to update token
    // POST /api/user/update-fcm-token
  }
}
```

---

## 📊 Expected Flow

```
1. User fills booking form in Flutter app
   ↓
2. App calls: POST /api/user/booking/create
   ↓
3. Customer Backend:
   - Validates data ✅
   - Creates booking in DB ✅
   - Finds best vendor ✅
   - Sends to vendor backend ✅
   - Sends FCM to vendor app ✅
   - Sends FCM to customer app ✅
   ↓
4. Vendor receives notification in their app ✅
   ↓
5. Vendor accepts/rejects ✅
   ↓
6. Customer receives status update ✅
```

---

## 🧪 Test Before Using in Flutter

Run this test to verify endpoint works:

```bash
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
```

Expected response:
```json
{
  "success": true,
  "message": "Booking created and vendor notified",
  "data": {
    "bookingId": 1,
    "status": "pending",
    ...
  }
}
```

---

## ✅ Checklist for Flutter Integration

- [ ] Update base URL to: `https://convenzcusb-backend.onrender.com`
- [ ] Use correct endpoint: `POST /api/user/booking/create`
- [ ] Include all required fields in request body
- [ ] Add proper error handling
- [ ] Set `Content-Type: application/json` header
- [ ] Handle 200/201 success responses
- [ ] Handle 400/404/500 error responses
- [ ] Update FCM token on login
- [ ] Listen for FCM notifications
- [ ] Show booking confirmation to user
- [ ] Display OTP when booking is accepted

---

**If you get 404, check:**
1. ✅ URL is: `https://convenzcusb-backend.onrender.com/api/user/booking/create`
2. ✅ Method is: `POST` (not GET)
3. ✅ Headers include: `Content-Type: application/json`
4. ✅ Body is valid JSON with all required fields
