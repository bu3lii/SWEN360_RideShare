import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/providers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
    
    if (!mounted) return;
    
    if (authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon Container with shadow
              Container(
                width: 128,
                height: 116,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 50,
                      offset: const Offset(0, 25),
                    ),
                  ],
                ),
                child: Center(
                  child: _buildCarIcon(),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 32),
              
              // App Title
              const Text(
                'RideShare',
                style: AppTextStyles.splashTitle,
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),
              
              const SizedBox(height: 12),
              
              // Tagline
              const Text(
                'Cut Costs, Share Rides, Go Green!',
                style: AppTextStyles.splashSubtitle,
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),
              
              const SizedBox(height: 48),
              
              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarIcon() {
    return const Icon(
      Iconsax.car,
      color: Colors.white,
      size: 80,
    );
  }
}