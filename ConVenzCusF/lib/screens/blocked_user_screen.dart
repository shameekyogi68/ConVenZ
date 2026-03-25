import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../utils/shared_prefs.dart';

class BlockedUserScreen extends StatelessWidget {
  final String blockReason;
  final String? blockedAt;

  const BlockedUserScreen({
    super.key,
    required this.blockReason,
    this.blockedAt,
  });

  Future<void> _logout(BuildContext context) async {
    // Clear all user data
    await SharedPrefs.clear();
    
    // Navigate to splash screen (which will redirect to login)
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/splash',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Block Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    size: 80,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Account Blocked',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Block Reason
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Reason:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        blockReason.isNotEmpty 
                            ? blockReason 
                            : 'Your account has been blocked by admin.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Information Text
                const Text(
                  'Your account has been temporarily suspended.\nPlease contact admin for assistance.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Contact Support (Optional)
                TextButton(
                  onPressed: () {
                    // TODO: Add contact support functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please email support@convenz.com for assistance'),
                        backgroundColor: AppColors.primaryTeal,
                      ),
                    );
                  },
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
