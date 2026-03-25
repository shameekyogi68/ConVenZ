# 🚫 User Blocking System - Frontend Integration Guide

## ✅ What Was Implemented

### Backend Features:
1. ✅ User blocking/unblocking by admin
2. ✅ Automatic block check on all user actions
3. ✅ Block reason and timestamp tracking
4. ✅ Admin endpoints for user management

---

## 🔒 Admin Endpoints

### Base URL
```
https://convenzcusb-backend.onrender.com/api/user/admin
```

### 1. Block User
```
POST /api/user/admin/block-user
```

**Request Body:**
```json
{
  "userId": 15,
  "blockReason": "Violation of terms" // optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "User blocked successfully",
  "data": {
    "userId": 15,
    "name": "ruhulesh",
    "phone": 9085214796,
    "isBlocked": true,
    "blockReason": "Violation of terms",
    "blockedAt": "2025-12-04T10:30:00.000Z"
  }
}
```

---

### 2. Unblock User
```
POST /api/user/admin/unblock-user
```

**Request Body:**
```json
{
  "userId": 15
}
```

**Response:**
```json
{
  "success": true,
  "message": "User unblocked successfully",
  "data": {
    "userId": 15,
    "name": "ruhulesh",
    "phone": 9085214796,
    "isBlocked": false
  }
}
```

---

### 3. Check Block Status
```
GET /api/user/admin/check-status/:userId
```

**Example:**
```
GET /api/user/admin/check-status/15
```

**Response:**
```json
{
  "success": true,
  "data": {
    "userId": 15,
    "name": "ruhulesh",
    "phone": 9085214796,
    "isBlocked": true,
    "blockReason": "Violation of terms",
    "blockedAt": "2025-12-04T10:30:00.000Z"
  }
}
```

---

## 📱 Flutter Customer App - What to Add

### 1. Handle Blocked User Response

When any API call returns 403 with `blocked: true`, show block message:

```dart
class ApiService {
  static Future<Map<String, dynamic>> makeRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://convenzcusb-backend.onrender.com$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      // Check if user is blocked
      if (response.statusCode == 403 && data['blocked'] == true) {
        // User is blocked - show blocking screen
        _handleBlockedUser(data);
        throw BlockedUserException(
          message: data['message'],
          blockReason: data['blockReason'],
          blockedAt: data['blockedAt'],
        );
      }

      return data;
    } catch (e) {
      rethrow;
    }
  }

  static void _handleBlockedUser(Map<String, dynamic> data) {
    // Navigate to blocked screen
    // Or show blocking dialog
    print('🚫 User is blocked: ${data['blockReason']}');
  }
}
```

---

### 2. Create Blocked User Exception

```dart
class BlockedUserException implements Exception {
  final String message;
  final String? blockReason;
  final String? blockedAt;

  BlockedUserException({
    required this.message,
    this.blockReason,
    this.blockedAt,
  });

  @override
  String toString() => message;
}
```

---

### 3. Create Blocked User Screen

```dart
import 'package:flutter/material.dart';

class BlockedUserScreen extends StatelessWidget {
  final String blockReason;
  final String? blockedAt;

  const BlockedUserScreen({
    Key? key,
    required this.blockReason,
    this.blockedAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Block Icon
                Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 100,
                ),
                
                SizedBox(height: 24),
                
                // Title
                Text(
                  'Account Blocked',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Reason
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Reason:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        blockReason,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Blocked At
                if (blockedAt != null)
                  Text(
                    'Blocked on: ${_formatDate(blockedAt!)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                
                SizedBox(height: 32),
                
                // Contact Support
                Text(
                  'Your account has been suspended.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                
                SizedBox(height: 8),
                
                Text(
                  'Please contact admin for assistance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade900,
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Logout Button
                ElevatedButton(
                  onPressed: () {
                    // Logout and return to login screen
                    _logout(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _logout(BuildContext context) {
    // Clear user data
    // Navigate to login screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }
}
```

---

### 4. Update Booking Creation

```dart
Future<void> createBooking() async {
  try {
    setState(() => isLoading = true);
    
    final result = await ApiService.makeRequest(
      '/api/user/booking/create',
      {
        'userId': currentUserId,
        'selectedService': selectedService,
        'jobDescription': jobDescription,
        'date': date,
        'time': time,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
      },
    );
    
    // Success
    if (result['success'] == true) {
      showSuccessDialog();
    }
    
  } on BlockedUserException catch (e) {
    // User is blocked - navigate to blocked screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BlockedUserScreen(
          blockReason: e.blockReason ?? 'Account suspended',
          blockedAt: e.blockedAt,
        ),
      ),
    );
  } catch (e) {
    // Other errors
    showErrorDialog(e.toString());
  } finally {
    setState(() => isLoading = false);
  }
}
```

---

### 5. Check Block Status on App Launch

```dart
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      // Get current user ID from shared preferences
      final userId = await _getCurrentUserId();
      
      if (userId == null) {
        // Not logged in - go to login
        _navigateToLogin();
        return;
      }

      // Check if user is blocked
      final response = await http.get(
        Uri.parse(
          'https://convenzcusb-backend.onrender.com/api/user/admin/check-status/$userId'
        ),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data']['isBlocked'] == true) {
        // User is blocked - show blocked screen
        _navigateToBlockedScreen(
          data['data']['blockReason'] ?? 'Account suspended',
          data['data']['blockedAt'],
        );
      } else {
        // User is active - go to home
        _navigateToHome();
      }

    } catch (e) {
      print('Error checking user status: $e');
      _navigateToLogin();
    }
  }

  void _navigateToBlockedScreen(String reason, String? blockedAt) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BlockedUserScreen(
          blockReason: reason,
          blockedAt: blockedAt,
        ),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<int?> _getCurrentUserId() async {
    // Get from shared preferences or secure storage
    return null; // Replace with actual implementation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
```

---

## 🎯 Admin Panel (Web/Flutter) - What to Add

### 1. Block User Function

```dart
Future<void> blockUser(int userId, String reason) async {
  try {
    final response = await http.post(
      Uri.parse('https://convenzcusb-backend.onrender.com/api/user/admin/block-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'blockReason': reason,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      print('✅ User blocked successfully');
      showSuccessMessage('User blocked successfully');
    } else {
      throw Exception(data['message']);
    }
  } catch (e) {
    print('❌ Error blocking user: $e');
    showErrorMessage('Failed to block user');
  }
}
```

---

### 2. Unblock User Function

```dart
Future<void> unblockUser(int userId) async {
  try {
    final response = await http.post(
      Uri.parse('https://convenzcusb-backend.onrender.com/api/user/admin/unblock-user'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
      print('✅ User unblocked successfully');
      showSuccessMessage('User unblocked successfully');
    } else {
      throw Exception(data['message']);
    }
  } catch (e) {
    print('❌ Error unblocking user: $e');
    showErrorMessage('Failed to unblock user');
  }
}
```

---

### 3. Admin User Management UI

```dart
class UserManagementScreen extends StatelessWidget {
  final int userId = 15;
  final String userName = 'ruhulesh';
  final String userPhone = '9085214796';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Management')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Card(
              child: ListTile(
                title: Text(userName),
                subtitle: Text('Phone: $userPhone\nUser ID: $userId'),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Block User Button
            ElevatedButton.icon(
              onPressed: () => _showBlockDialog(context),
              icon: Icon(Icons.block),
              label: Text('Block User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            
            SizedBox(height: 12),
            
            // Unblock User Button
            ElevatedButton.icon(
              onPressed: () => _confirmUnblock(context),
              icon: Icon(Icons.check_circle),
              label: Text('Unblock User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to block this user?'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Block Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              blockUser(userId, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Block'),
          ),
        ],
      ),
    );
  }

  void _confirmUnblock(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock User'),
        content: Text('Are you sure you want to unblock this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              unblockUser(userId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🧪 Testing

### Test Blocking User

```bash
curl -X POST https://convenzcusb-backend.onrender.com/api/user/admin/block-user \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 15,
    "blockReason": "Testing blocking functionality"
  }'
```

### Test Creating Booking as Blocked User

```bash
curl -X POST https://convenzcusb-backend.onrender.com/api/user/booking/create \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 15,
    "selectedService": "Plumbing",
    "jobDescription": "Test",
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
  "success": false,
  "message": "Your account has been blocked by admin. Please contact support.",
  "blocked": true,
  "blockReason": "Testing blocking functionality",
  "blockedAt": "2025-12-04T...",
  "supportContact": "Contact admin for assistance"
}
```

### Test Unblocking

```bash
curl -X POST https://convenzcusb-backend.onrender.com/api/user/admin/unblock-user \
  -H "Content-Type: application/json" \
  -d '{"userId": 15}'
```

---

## ✅ Summary

### Backend (Already Implemented):
- ✅ `isBlocked` field added to User model
- ✅ Block middleware checks all user actions
- ✅ Admin endpoints for block/unblock
- ✅ Block reason and timestamp tracking
- ✅ Proper error responses with block details

### Frontend (To Add):
1. ✅ Handle 403 blocked responses in API calls
2. ✅ Create BlockedUserScreen to show block message
3. ✅ Check block status on app launch
4. ✅ Admin panel to block/unblock users
5. ✅ Logout blocked users automatically

### Protected Routes:
- ✅ Booking creation
- ✅ Profile updates
- ✅ Location updates
- ✅ FCM token updates
- ✅ View bookings
- ✅ Cancel bookings

### Unprotected Routes:
- ✅ Register (OTP generation)
- ✅ Verify OTP (need to login to see block status)
- ✅ Status updates from vendor backend

**No errors. All existing functionality preserved. Blocking system ready!**
