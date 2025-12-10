import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  bool _isLoading = false;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
      }
    }
  }

  Future<void> _deactivateAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Account'),
        content: const Text(
          'Are you sure you want to deactivate your account? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      final success = await _userService.deactivateAccount();
      setState(() => _isLoading = false);

      if (success && mounted) {
        await context.read<AuthProvider>().logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
        }
      }
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
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
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: user?.profilePicture != null
                              ? ClipOval(
                                  child: Image.network(
                                    user!.profilePicture!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  user?.initials ?? 'U',
                                  style: AppTextStyles.h1.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Iconsax.camera,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'User',
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatItem(
                          icon: Iconsax.star1,
                          value: user?.rating.average.toStringAsFixed(1) ?? '0.0',
                          label: 'Rating',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          color: AppColors.border,
                        ),
                        _StatItem(
                          icon: Iconsax.car,
                          value: user?.stats.totalRides.toString() ?? '0',
                          label: 'Total Rides',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          color: AppColors.border,
                        ),
                        _StatItem(
                          icon: Iconsax.money,
                          value: '${user?.stats.moneySaved.toStringAsFixed(0) ?? '0'}',
                          label: 'BHD Saved',
                        ),
                      ],
                    ),
                    if (user?.isDriver == true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.verify5,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Driver',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 24),

              // Menu Items
              _MenuSection(
                title: 'Account',
                items: [
                  _MenuItem(
                    icon: Iconsax.user_edit,
                    title: 'Edit Profile',
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  ),
                  if (user?.isDriver != true)
                    _MenuItem(
                      icon: Iconsax.car,
                      title: 'Become a Driver',
                      onTap: () => Navigator.pushNamed(context, '/become-driver'),
                    ),
                  _MenuItem(
                    icon: Iconsax.lock,
                    title: 'Change Password',
                    onTap: () => Navigator.pushNamed(context, '/change-password'),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              _MenuSection(
                title: 'Activity',
                items: [
                  _MenuItem(
                    icon: Iconsax.clock,
                    title: 'Ride History',
                    onTap: () => Navigator.pushNamed(context, '/ride-history'),
                  ),
                  _MenuItem(
                    icon: Iconsax.receipt_2,
                    title: 'My Bookings',
                    onTap: () => Navigator.pushNamed(context, '/my-bookings'),
                  ),
                  if (user?.isDriver == true)
                    _MenuItem(
                      icon: Iconsax.routing,
                      title: 'My Rides',
                      onTap: () => Navigator.pushNamed(context, '/my-rides'),
                    ),
                  _MenuItem(
                    icon: Iconsax.star,
                    title: 'Reviews',
                    onTap: () => Navigator.pushNamed(context, '/reviews'),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              _MenuSection(
                title: 'Support',
                items: [
                  _MenuItem(
                    icon: Iconsax.message_question,
                    title: 'Help & Support',
                    onTap: () => _showInfoDialog(
                      'Help & Support',
                      'For support, please contact:\n\nEmail: support@uniride.bh\nPhone: +973 1234 5678\n\nOr visit the AUBH Student Services office.',
                    ),
                  ),
                  _MenuItem(
                    icon: Iconsax.document_text,
                    title: 'About UniRide',
                    onTap: () => _showInfoDialog(
                      'About UniRide',
                      'UniRide v1.0.0\n\nA carpooling app for AUBH students to share rides, save money, and reduce their carbon footprint.\n\n© 2024 AUBH UniRide Team',
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Iconsax.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

              const SizedBox(height: 12),

              // Deactivate Account
              TextButton(
                onPressed: _deactivateAccount,
                child: Text(
                  'Deactivate Account',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(color: AppColors.primary),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Iconsax.arrow_right_3,
        color: AppColors.textSecondary,
        size: 18,
      ),
    );
  }
}