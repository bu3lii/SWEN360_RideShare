import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../config/theme.dart';
import '../services/review_service.dart';
import '../widgets/widgets.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _reviewService = ReviewService();
  List<Review> _reviews = [];
  ReviewStats? _stats;
  bool _isLoading = true;
  String _selectedType = 'received';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadReviews();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _selectedType = _tabController.index == 0 ? 'received' : 'given';
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoading = true);

    final reviews = await _reviewService.getMyReviews(type: _selectedType);

    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await _reviewService.getReviewStats();
    if (mounted && stats != null) {
      setState(() => _stats = stats);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reviews'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Given'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats Card
          if (_stats != null && _selectedType == 'received')
            Container(
              margin: const EdgeInsets.all(16),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _stats!.averageRating.toStringAsFixed(1),
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < _stats!.averageRating.round()
                                    ? Iconsax.star1
                                    : Iconsax.star,
                                color: AppColors.rating,
                                size: 20,
                              );
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_stats!.totalReviews} reviews',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Rating Distribution
                  ...List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = _stats!.ratingDistribution[rating] ?? 0;
                    final percentage = _stats!.totalReviews > 0
                        ? count / _stats!.totalReviews
                        : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            '$rating',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Iconsax.star1,
                            color: AppColors.rating,
                            size: 14,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: AppColors.border,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.rating,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 30,
                            child: Text(
                              count.toString(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

          // Reviews List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadReviews,
              color: AppColors.primary,
              child: _isLoading
                  ? const Center(child: LoadingIndicator())
                  : _reviews.isEmpty
                      ? _EmptyState(type: _selectedType)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return _ReviewCard(
                              review: review,
                              isReceived: _selectedType == 'received',
                              onRespond: _selectedType == 'received'
                                  ? () => _showRespondDialog(review)
                                  : null,
                            ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1, end: 0);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRespondDialog(Review review) async {
    if (review.response != null) return;

    final controller = TextEditingController();
    final response = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Review'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Write your response...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (response != null && response.isNotEmpty) {
      final success = await _reviewService.respondToReview(review.id, response);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadReviews();
      }
    }
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final bool isReceived;
  final VoidCallback? onRespond;

  const _ReviewCard({
    required this.review,
    required this.isReceived,
    this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final user = isReceived ? review.reviewer : review.reviewee;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: user?.profilePicture != null
                    ? ClipOval(
                        child: Image.network(
                          user!.profilePicture!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        user?.initials ?? 'U',
                        style: AppTextStyles.bodyMedium.copyWith(
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
                      user?.name ?? 'Anonymous',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timeago.format(review.createdAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
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
                    size: 16,
                  );
                }),
              ),
            ],
          ),

          // Comment
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // Tags
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: review.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Response
          if (review.response != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.message_text,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Your Response',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.response!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isReceived && onRespond != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRespond,
              icon: const Icon(Iconsax.message_text, size: 16),
              label: const Text('Respond'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String type;

  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.star,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            type == 'received'
                ? 'No reviews received yet'
                : 'No reviews given yet',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type == 'received'
                ? 'Complete rides to get reviews'
                : 'Review your completed rides',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}