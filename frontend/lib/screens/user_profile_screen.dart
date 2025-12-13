import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../models/models.dart';
import '../services/user_service.dart';
import '../services/review_service.dart';
import '../services/message_service.dart';
import '../widgets/widgets.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _userService = UserService();
  final _reviewService = ReviewService();
  final _messageService = MessageService();
  User? _user;
  List<Review> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final user = await _userService.getUser(widget.userId);
    final reviews = await _reviewService.getUserReviews(widget.userId);

    if (mounted) {
      setState(() {
        _user = user;
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _user == null
              ? const Center(child: Text('User not found'))
              : CustomScrollView(
                  slivers: [
                    // App Bar with profile header
                    SliverAppBar(
                      expandedHeight: 280,
                      pinned: true,
                      backgroundColor: AppColors.primary,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: AppColors.splashGradient,
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: _user!.profilePicture != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _user!.profilePicture!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Text(
                                          _user!.initials,
                                          style: AppTextStyles.h1.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _user!.name,
                                  style: AppTextStyles.h2.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Iconsax.star1,
                                      color: AppColors.rating,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_user!.rating.average.toStringAsFixed(1)} (${_user!.rating.count} reviews)',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_user!.isDriver) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Iconsax.verify5,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Verified Driver',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      leading: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Iconsax.arrow_left,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          onPressed: () async {
                            if (_user == null) return;
                            
                            // Find existing conversation or create new one by sending a message
                            final conversations = await _messageService.getConversations();
                            Conversation? existingConversation;
                            
                            for (var conv in conversations) {
                              if (conv.participant?.oderId == widget.userId) {
                                existingConversation = conv;
                                break;
                              }
                            }
                            
                            if (existingConversation != null) {
                              // Navigate to existing conversation
                              if (mounted) {
                                Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: existingConversation,
                                );
                              }
                            } else {
                              // Create new conversation by sending an initial message
                              // The backend will automatically create the conversation
                              final message = await _messageService.sendMessage(
                                recipientId: widget.userId,
                                content: 'Hi!',
                              );
                              
                              if (message != null && mounted) {
                                // Reload conversations to get the new one
                                final updatedConversations = await _messageService.getConversations();
                                final newConversation = updatedConversations.firstWhere(
                                  (conv) => conv.participant?.oderId == widget.userId,
                                  orElse: () => updatedConversations.first,
                                );
                                
                                Navigator.pushNamed(
                                  context,
                                  '/chat',
                                  arguments: newConversation,
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to start conversation'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Iconsax.message,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Stats
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatItem(
                                icon: Iconsax.car,
                                value: _user!.stats.totalRidesAsDriver.toString(),
                                label: 'Rides Given',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _StatItem(
                                icon: Iconsax.user,
                                value: _user!.stats.totalRidesAsRider.toString(),
                                label: 'Rides Taken',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 50,
                              color: AppColors.border,
                            ),
                            Expanded(
                              child: _StatItem(
                                icon: Iconsax.calendar,
                                value: _memberSince,
                                label: 'Member Since',
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                    ),

                    // Car Details (if driver)
                    if (_user!.isDriver && _user!.carDetails != null)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
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
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Iconsax.car,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user!.carDetails!.model,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_user!.carDetails!.color} • ${_user!.carDetails!.totalSeats} seats',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                      ),

                    // Reviews Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              'Reviews',
                              style: AppTextStyles.h3,
                            ),
                            const Spacer(),
                            Text(
                              '${_reviews.length} reviews',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Reviews List
                    _reviews.isEmpty
                        ? SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Iconsax.star,
                                      size: 48,
                                      color: AppColors.textSecondary.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No reviews yet',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final review = _reviews[index];
                                return _ReviewCard(review: review)
                                    .animate(delay: (50 * index).ms)
                                    .fadeIn()
                                    .slideX(begin: 0.1, end: 0);
                              },
                              childCount: _reviews.length,
                            ),
                          ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 20),
                    ),
                  ],
                ),
    );
  }

  String get _memberSince {
    final months = DateTime.now().difference(_user!.createdAt).inDays ~/ 30;
    if (months < 1) return 'New';
    if (months < 12) return '${months}mo';
    return '${months ~/ 12}yr';
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
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(color: AppColors.primary),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  review.reviewer?.initials ?? 'A',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewer?.name ?? 'Anonymous',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Iconsax.star1 : Iconsax.star,
                    color: AppColors.rating,
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}