import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../widgets/widgets.dart';

class SafetyCenterScreen extends StatefulWidget {
  const SafetyCenterScreen({super.key});

  @override
  State<SafetyCenterScreen> createState() => _SafetyCenterScreenState();
}

class _SafetyCenterScreenState extends State<SafetyCenterScreen> {
  Timer? _sosTimer;
  bool _isSosPressed = false;
  int _sosHoldSeconds = 0;
  
  String? _emergencyContactName;
  String? _emergencyContactPhone;
  String? _emergencyContactRelation;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContact();
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyContactName = prefs.getString('emergency_contact_name');
      _emergencyContactPhone = prefs.getString('emergency_contact_phone');
      _emergencyContactRelation = prefs.getString('emergency_contact_relation');
    });
  }

  Future<void> _saveEmergencyContact(String name, String phone, String relation) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contact_name', name);
    await prefs.setString('emergency_contact_phone', phone);
    await prefs.setString('emergency_contact_relation', relation);
    setState(() {
      _emergencyContactName = name;
      _emergencyContactPhone = phone;
      _emergencyContactRelation = relation;
    });
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot make phone call to $number')),
        );
      }
    }
  }

  void _startSosTimer() {
    _sosTimer?.cancel();
    _sosHoldSeconds = 0;
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sosHoldSeconds++;
      });
      if (_sosHoldSeconds >= 3) {
        _activateSos();
        timer.cancel();
      }
    });
  }

  void _cancelSosTimer() {
    _sosTimer?.cancel();
    setState(() {
      _isSosPressed = false;
      _sosHoldSeconds = 0;
    });
  }

  void _activateSos() {
    _sosTimer?.cancel();
    // Call emergency number 999
    _callNumber('999');
    setState(() {
      _isSosPressed = false;
      _sosHoldSeconds = 0;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency SOS activated - calling 999'),
          backgroundColor: Color(0xFFFB2C36),
        ),
      );
    }
  }

  void _showEditEmergencyContactDialog() {
    final nameController = TextEditingController(text: _emergencyContactName ?? '');
    final phoneController = TextEditingController(text: _emergencyContactPhone ?? '');
    final relationController = TextEditingController(text: _emergencyContactRelation ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter contact name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+973 XXXX XXXX',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g., Father, Mother, Friend',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _saveEmergencyContact(
                nameController.text.trim(),
                phoneController.text.trim(),
                relationController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Center'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOS Button Section
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 223),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFB2C36), Color(0xFFEC003F)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    right: -64,
                    top: -64,
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.warning_2,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 85),
                        const Text(
                          'Emergency SOS',
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Press and hold for 3 seconds',
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTapDown: (_) {
                            setState(() => _isSosPressed = true);
                            _startSosTimer();
                          },
                          onTapUp: (_) => _cancelSosTimer(),
                          onTapCancel: () => _cancelSosTimer(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 17.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _isSosPressed && _sosHoldSeconds < 3
                                    ? 'Hold... ${3 - _sosHoldSeconds}'
                                    : 'Hold to Activate SOS',
                                style: const TextStyle(
                                  fontFamily: 'Arimo',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFE7000B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Emergency Contacts Section
            const Text(
              'EMERGENCY CONTACTS - BAHRAIN',
              style: TextStyle(
                fontFamily: 'Arimo',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6A7282),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
            
            const SizedBox(height: 12),
            
            // Ambulance
            _EmergencyContactCard(
              icon: Iconsax.heart,
              iconColor: const Color(0xFFFB2C36),
              iconBg: const Color(0xFFFB2C36),
              title: 'Ambulance',
              subtitle: 'Medical Emergency',
              phone: '999',
              borderColor: const Color(0xFFFFE2E2),
              onTap: () => _callNumber('999'),
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 12),
            
            // Police
            _EmergencyContactCard(
              icon: Iconsax.shield_security,
              iconColor: Colors.white,
              iconBg: const Color(0xFF155DFC),
              title: 'Bahrain Police',
              subtitle: 'General Emergency',
              phone: '999',
              borderColor: const Color(0xFFDBEAFE),
              onTap: () => _callNumber('999'),
            ).animate().fadeIn(duration: 400.ms, delay: 150.ms).slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 12),
            
            // Traffic Police
            _EmergencyContactCard(
              icon: Iconsax.car,
              iconColor: Colors.white,
              iconBg: const Color(0xFFFE9A00),
              title: 'Traffic Police',
              subtitle: 'Road Accidents',
              phone: '199',
              borderColor: const Color(0xFFFEF3C6),
              onTap: () => _callNumber('199'),
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 12),
            
            // AUBH Security (empty button)
            Container(
              padding: const EdgeInsets.all(17.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF0FDFA), Color(0xFFECFDF5)],
                ),
                border: Border.all(color: const Color(0xFF32C7AC), width: 1.5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF32C7AC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Iconsax.shield_tick,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AUBH Security',
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1D293D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Campus Safety Office',
                          style: TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4A5565),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 55,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF32C7AC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Call',
                        style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 250.ms).slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 24),
            
            // My Emergency Contact Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MY EMERGENCY CONTACT',
                  style: TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6A7282),
                  ),
                ),
                GestureDetector(
                  onTap: _showEditEmergencyContactDialog,
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontFamily: 'Arimo',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF32C7AC),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            
            const SizedBox(height: 12),
            
            // Emergency Contact Card
            if (_emergencyContactName != null && _emergencyContactName!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(17.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFC27AFF), Color(0xFF9810FA)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(_emergencyContactName),
                          style: const TextStyle(
                            fontFamily: 'Arimo',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _emergencyContactName ?? '',
                            style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF1D293D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_emergencyContactRelation ?? ''} • ${_emergencyContactPhone ?? ''}',
                            style: const TextStyle(
                              fontFamily: 'Arimo',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF4A5565),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _callNumber(_emergencyContactPhone ?? ''),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.call,
                          color: Color(0xFF4A5565),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 350.ms).slideX(begin: -0.1, end: 0)
            else
              Container(
                padding: const EdgeInsets.all(17.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.add_circle,
                      color: Color(0xFF4A5565),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Add your emergency contact',
                        style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF4A5565),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showEditEmergencyContactDialog,
                      child: const Text(
                        'Add',
                        style: TextStyle(
                          fontFamily: 'Arimo',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF32C7AC),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 350.ms).slideX(begin: -0.1, end: 0),
          ],
        ),
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String phone;
  final Color borderColor;
  final VoidCallback onTap;

  const _EmergencyContactCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17.5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1D293D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF4A5565),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 55,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  phone,
                  style: const TextStyle(
                    fontFamily: 'Arimo',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

