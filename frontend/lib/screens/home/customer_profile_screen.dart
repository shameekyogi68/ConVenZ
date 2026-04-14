import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';
import '../../utils/shared_prefs.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/text_input.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  ProfileModel? profile;
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final FocusNode nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() => isLoading = true);
    
    // Fallback: Populate from SharedPrefs first so UI is never fully empty while loading
    nameController.text = SharedPrefs.getUserName() ?? SharedPrefs.getPhone() ?? 'User';
    phoneController.text = SharedPrefs.getPhone() ?? '';
    addressController.text = '';

    try {
      final Map<String, dynamic> response = await ProfileService.getProfile();
      if (!mounted) {
        return;
      }

      if (response['success'] == true && response['data'] != null) {
        final p = ProfileModel.fromJson(response['data'] as Map<String, dynamic>);
        setState(() {
          profile = p;
          nameController.text = p.name.isNotEmpty ? p.name : nameController.text;
          phoneController.text = p.phone.isNotEmpty ? p.phone : phoneController.text;
          addressController.text = p.address.isNotEmpty && p.address != 'No address set' ? p.address : 'Not set';
        });
      } else {
        setState(() => profile = null);
      }
    } catch (_) {
      if (mounted) {
        addressController.text = 'Not set';
        setState(() => profile = null);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    final String name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter your name', isError: true);
      return;
    }

    setState(() => isSaving = true);
    try {
      final Map<String, dynamic> response = await ProfileService.updateProfile(name: name);
      if (!mounted) {
        return;
      }

      if (response['success'] == true) {
        _showSnackBar('Profile updated successfully ✓');
        setState(() => isEditing = false);
        await _fetchProfile();
      } else {
        _showSnackBar('Could not save changes. Please try again.', isError: true);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Connection error. Try again later.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await SharedPrefs.clear();
      if (mounted) {
        context.go('/welcomeCarousel');
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isLoading)
            IconButton(
              icon: Icon(
                isEditing ? Icons.close_rounded : Icons.edit_rounded,
                color: AppColors.primaryTeal,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  if (isEditing) {
                    // Cancel: restore saved name
                    nameController.text = profile?.name ?? SharedPrefs.getUserName() ?? '';
                    isEditing = false;
                    FocusScope.of(context).unfocus();
                  } else {
                    isEditing = true;
                    Future.microtask(() => nameFocusNode.requestFocus());
                  }
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withOpacity(0.15),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: ClipOval(child: Image.asset('assets/images/avatar.png', width: 110)),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 12),

                    // Display name below avatar
                    Text(
                      nameController.text.isNotEmpty ? nameController.text : 'Your Name',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ).animate().fade(delay: 150.ms).slideY(begin: 0.1, end: 0, duration: 350.ms),

                    Text(
                      phoneController.text.isNotEmpty ? '+91 ${phoneController.text}' : '',
                      style: const TextStyle(fontSize: 13, color: AppColors.darkGrey),
                    ).animate().fade(delay: 200.ms),

                    const SizedBox(height: 36),

                    // ── Fields ──
                    TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      readOnly: !isEditing,
                      style: TextStyle(
                        color: isEditing ? AppColors.primaryTeal : AppColors.darkGrey,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primaryTeal),
                        labelText: 'Full Name',
                        labelStyle: const TextStyle(color: AppColors.darkGrey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Phone — read-only
                    AbsorbPointer(
                      child: TextInput(
                        controller: phoneController,
                        labelText: 'Phone Number',
                        icon: Icons.phone_android_rounded,
                        prefixText: '+91 ',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Address — auto-detected, read-only
                    AbsorbPointer(
                      child: TextField(
                        controller: addressController,
                        maxLines: 2,
                        readOnly: true,
                        style: const TextStyle(fontSize: 14, color: AppColors.darkGrey),
                        decoration: InputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(top: 14),
                            child: Icon(Icons.location_on_outlined, color: AppColors.primaryTeal),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 50),
                          labelText: 'Detected Address',
                          labelStyle: const TextStyle(color: AppColors.darkGrey),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.primaryTeal),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Save button — only while editing
                    if (isEditing)
                      Column(
                        children: [
                          if (isSaving) const CircularProgressIndicator(color: AppColors.primaryTeal) else PrimaryButton(text: 'Save Changes', onPressed: _saveProfile),
                          const SizedBox(height: 20),
                        ],
                      ).animate().fade().slideY(begin: 0.15, end: 0, duration: 250.ms),

                    // ── Danger Zone ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.dangerRed.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGrey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _logout,
                            child: Row(
                              children: [
                                const Icon(Icons.logout_rounded, color: AppColors.dangerRed, size: 20),
                                const SizedBox(width: 12),
                                const Text(
                                  'Log Out',
                                  style: TextStyle(
                                    color: AppColors.dangerRed,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.arrow_forward_ios_rounded, color: AppColors.dangerRed.withOpacity(0.5), size: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
