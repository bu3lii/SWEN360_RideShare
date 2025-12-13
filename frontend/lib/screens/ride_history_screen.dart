import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/user_service.dart';
import '../widgets/widgets.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _userService = UserService();
  List<RideHistoryItem> _history = [];
  bool _isLoading = true;
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    switch (_tabController.index) {
      case 0:
        _selectedType = 'all';
        break;
      case 1:
        _selectedType = 'passenger';
        break;
      case 2:
        _selectedType = 'driver';
        break;
    }
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final history = await _userService.getRideHistory(type: _selectedType);

    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'As Passenger'),
            Tab(text: 'As Driver'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: LoadingIndicator())
            : _history.isEmpty
                ? _EmptyState(type: _selectedType)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return _HistoryCard(item: item)
                          .animate(delay: (50 * index).ms)
                          .fadeIn()
                          .slideX(begin: 0.1, end: 0);
                    },
                  ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final RideHistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDriver = item.type == 'driver';
    final ride = item.ride;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDriver ? AppColors.primary : AppColors.secondary)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDriver ? Iconsax.driving : Iconsax.user,
                        color: isDriver ? AppColors.primary : AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDriver ? 'You drove' : 'You rode with',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (!isDriver && ride?.driver != null)
                            Text(
                              ride!.driver!.name,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (isDriver && item.passengers != null)
                            Text(
                              '${item.passengers!.length} passenger${item.passengers!.length != 1 ? 's' : ''}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('MMM dd').format(item.date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (ride != null)
                          Text(
                            DateFormat('HH:mm').format(ride.departureTime),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                if (ride != null) ...[
                  const SizedBox(height: 16),

                  // Route
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 24,
                            color: AppColors.border,
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.startLocation.address,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ride.destination.address,
                              style: AppTextStyles.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                if (isDriver && item.totalEarnings != null) ...[
                  const Icon(
                    Iconsax.money_recive,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Earned: ${item.totalEarnings!.toStringAsFixed(2)} BHD',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else if (!isDriver && item.booking != null) ...[
                  const Icon(
                    Iconsax.money_send,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Paid: ${item.booking!.totalAmount.toStringAsFixed(2)} BHD',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                if (!isDriver && item.booking != null && !item.booking!.hasReviewed)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/create-review',
                        arguments: {
                          'rideId': ride?.id,
                          'bookingId': item.booking!.id,
                          'revieweeId': ride?.driver?.id,
                        },
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Leave Review'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String type;

  const _EmptyState({required this.type});

  String get _message {
    switch (type) {
      case 'passenger':
        return 'No rides as passenger yet';
      case 'driver':
        return 'No rides as driver yet';
      default:
        return 'No ride history yet';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.clock,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _message,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed rides will appear here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/available-rides'),
            child: const Text('Find a Ride'),
          ),
        ],
      ),
    );
  }
}