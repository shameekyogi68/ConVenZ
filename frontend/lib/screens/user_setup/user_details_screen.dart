import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/text_input.dart';
import '../../services/auth_service.dart';
import '../../utils/shared_prefs.dart';

class UserDetailsScreen extends StatefulWidget {
  final PageController controller;
  const UserDetailsScreen({super.key, required this.controller});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final TextEditingController nameController = TextEditingController();
  String? selectedGender;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void continueNext() async {
    FocusScope.of(context).unfocus();

    final name = nameController.text.trim();

    if (name.isEmpty) {
      _showError('Please enter your full name');
      return;
    }
    if (name.length < 2) {
      _showError('Name must be at least 2 characters');
      return;
    }
    if (selectedGender == null) {
      _showError('Please select your gender');
      return;
    }

    final phone = SharedPrefs.getPhone();
    if (phone == null) {
      _showError('Phone number missing. Please restart onboarding.');
      return;
    }

    setState(() => _isLoading = true);
    final response = await AuthService.updateUserDetails(phone, name, selectedGender!);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      widget.controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    } else {
      _showError(response['message']?.toString() ?? 'Something went wrong. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void goBack() {
    if (widget.controller.hasClients) {
      widget.controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              // Back button
              Positioned(
                top: 20,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryTeal),
                  onPressed: _isLoading ? null : goBack,
                ),
              ),

              // Main content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    Image.asset('assets/images/logo.png', width: 150),
                    const SizedBox(height: 80),
                    const Text(
                      'Your Details',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us a bit about yourself',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 40),
                    TextInput(
                      controller: nameController,
                      labelText: 'Full Name *',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: 'Gender *',
                          labelStyle: TextStyle(
                            color: AppColors.darkGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: selectedGender,
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) => setState(() => selectedGender = value),
                      ),
                    ),
                    const SizedBox(height: 40),
                    PrimaryButton(
                      text: 'Continue',
                      onPressed: _isLoading ? null : continueNext,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
