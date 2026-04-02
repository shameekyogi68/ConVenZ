import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../widgets/text_input.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';
import '../../utils/shared_prefs.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomerProfileScreen extends StatefulWidget {
  final PageController controller;
  const CustomerProfileScreen({super.key, required this.controller});

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
    addressController.text = 'Fetching address...';

    try {
      final response = await ProfileService.getProfile();
      if (!mounted) return;

      if (response['success'] == true && response['data'] != null) {
        final p = ProfileModel.fromJson(response['data'] as Map<String, dynamic>);
        setState(() {
          profile = p;
          nameController.text = p.name.isNotEmpty ? p.name : nameController.text;
          phoneController.text = p.phone.isNotEmpty ? p.phone : phoneController.text;
          addressController.text = p.address.isNotEmpty && p.address != 'No address set' ? p.address : addressController.text;
        });
      } else {
        setState(() => profile = null);
      }
    } catch (_) {
      if (mounted) setState(() => profile = null);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter your name', isError: true);
      return;
    }

    setState(() => isSaving = true);
    try {
      final response = await ProfileService.updateProfile(name: name);
      if (!mounted) return;

      if (response['success'] == true) {
        _showSnackBar('Profile updated successfully ✓');
        setState(() => isEditing = false);
        await _fetchProfile();
      } else {
        _showSnackBar('Could not save changes. Please try again.', isError: true);
      }
    } catch (_) {
      if (mounted) _showSnackBar('Connection error. Try again later.', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed == true) {
      await SharedPrefs.clear();
      if (mounted) context.go('/welcomeCarousel');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryTeal.withOpacity(0.1), blurRadius: 20, spreadRadius: 5),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: ClipOval(child: Image.asset('assets/images/avatar.png', width: 130)),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 20),

                    const Text(
                      'Customer Profile',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryTeal,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

                    const SizedBox(height: 40),

                    // Name field — editable
                    TextField(
                      controller: nameController,
                      focusNode: nameFocusNode,
                      readOnly: !isEditing,
                      onTap: () {
                        setState(() => isEditing = true);
                        nameFocusNode.requestFocus();
                      },
                      style: TextStyle(
                        color: isEditing ? AppColors.primaryTeal : AppColors.darkGrey,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person, color: AppColors.primaryTeal),
                        labelText: 'Name',
                        labelStyle: TextStyle(
                          color: isEditing ? AppColors.primaryTeal : AppColors.darkGrey,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(color: AppColors.primaryTeal),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(color: AppColors.primaryTeal),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Phone — read-only
                    AbsorbPointer(
                      child: TextInput(
                        controller: phoneController,
                        labelText: 'Phone Number',
                        icon: Icons.phone_android,
                        prefixText: '+91 ',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Address — auto-detected, read-only
                    AbsorbPointer(
                      child: TextField(
                        controller: addressController,
                        maxLines: 3,
                        readOnly: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on, color: AppColors.primaryTeal),
                          labelText: 'Address',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppColors.primaryTeal),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Save button — only while editing
                    if (isEditing)
                      Column(
                        children: [
                          isSaving
                              ? const CircularProgressIndicator(color: AppColors.primaryTeal)
                              : PrimaryButton(text: 'Save Changes', onPressed: _saveProfile),
                          const SizedBox(height: 16),
                        ],
                      ).animate().fade().slideY(begin: 0.2, end: 0, duration: 300.ms),

                    SecondaryButton(text: 'Log Out', onPressed: _logout)
                        .animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),

                    const SizedBox(height: 40),
                  ].animate(interval: 50.ms).fade(duration: 400.ms),
                ),
              ),
            ),
    );
  }
}