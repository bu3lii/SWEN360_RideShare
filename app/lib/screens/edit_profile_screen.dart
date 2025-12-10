import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../widgets/widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedUser = await _userService.updateProfile(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (updatedUser != null && mounted) {
      context.read<AuthProvider>().updateUser(updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: user?.profilePicture != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.profilePicture!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                user?.initials ?? 'U',
                                style: AppTextStyles.h1.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 40,
                                ),
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Implement image picker
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(
                              Iconsax.camera,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 32),

                // Form Fields
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name Field
                      Text(
                        'Full Name',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _nameController,
                        hintText: 'Enter your full name',
                        prefixIcon: Iconsax.user,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Email Field (Read-only)
                      Text(
                        'Email',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.sms,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                user?.email ?? '',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const Icon(
                              Iconsax.lock,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email cannot be changed',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Phone Number Field
                      Text(
                        'Phone Number',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _phoneController,
                        hintText: 'Enter your phone number',
                        prefixIcon: Iconsax.call,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // University ID (Read-only)
                      Text(
                        'University ID',
                        style: AppTextStyles.label,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.card,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                user?.universityId ?? '',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const Icon(
                              Iconsax.lock,
                              color: AppColors.textSecondary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 32),

                // Save Button
                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: _saveProfile,
                  isLoading: _isLoading,
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}