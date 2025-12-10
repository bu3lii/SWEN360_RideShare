import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../config/theme.dart';
import '../services/review_service.dart';
import '../widgets/widgets.dart';

class CreateReviewScreen extends StatefulWidget {
  final String rideId;
  final String bookingId;
  final String revieweeId;
  final String? revieweeName;

  const CreateReviewScreen({
    super.key,
    required this.rideId,
    required this.bookingId,
    required this.revieweeId,
    this.revieweeName,
  });

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final _reviewService = ReviewService();
  final _commentController = TextEditingController();
  int _rating = 0;
  final Set<String> _selectedTags = {};
  bool _isLoading = false;

  final List<String> _availableTags = [
    'Punctual',
    'Friendly',
    'Clean Car',
    'Safe Driver',
    'Good Communication',
    'Comfortable Ride',
    'Professional',
    'Helpful',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final review = await _reviewService.createReview(
      rideId: widget.rideId,
      bookingId: widget.bookingId,
      revieweeId: widget.revieweeId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      tags: _selectedTags.isEmpty ? null : _selectedTags.toList(),
    );

    setState(() => _isLoading = false);

    if (review != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit review'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave a Review'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.star1,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'How was your ride${widget.revieweeName != null ? ' with ${widget.revieweeName}' : ''}?',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your feedback helps improve the community',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

              const SizedBox(height: 32),

              // Rating Stars
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
                    Text(
                      'Tap to rate',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starRating = index + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _rating = starRating),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              starRating <= _rating
                                  ? Iconsax.star1
                                  : Iconsax.star,
                              color: AppColors.rating,
                              size: 40,
                            ).animate(target: starRating <= _rating ? 1 : 0)
                              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
                              .then()
                              .scale(begin: const Offset(1.2, 1.2), end: const Offset(1, 1)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ratingText,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              // Tags
              Text(
                'What did you like? (Optional)',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag);
                        } else {
                          _selectedTags.add(tag);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

              const SizedBox(height: 24),

              // Comment
              Text(
                'Additional Comments (Optional)',
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _commentController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    counterStyle: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

              const SizedBox(height: 32),

              // Submit Button
              PrimaryButton(
                text: 'Submit Review',
                onPressed: _submitReview,
                isLoading: _isLoading,
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

              const SizedBox(height: 16),

              // Skip Button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Skip for now',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

  String get _ratingText {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}