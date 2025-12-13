import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import '../config/theme.dart';

class MapRibbon extends StatelessWidget {
  final VoidCallback onTap;
  final int nearbyRidesCount;
  final LatLng? currentLocation;

  const MapRibbon({
    super.key,
    required this.onTap,
    this.nearbyRidesCount = 0,
    this.currentLocation,
  });

  // Bahrain center
  static const LatLng _defaultCenter = LatLng(26.0667, 50.5577);

  @override
  Widget build(BuildContext context) {
    final center = currentLocation ?? _defaultCenter;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Mini Map
              IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 12,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.uniride',
                    ),
                    // Current location marker
                    if (currentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: currentLocation!,
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),

              // Content
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Iconsax.map,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Live Map',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            nearbyRidesCount > 0
                                ? '$nearbyRidesCount rides nearby'
                                : 'See rides around you',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Iconsax.arrow_right_3,
                            color: AppColors.primary,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Pulse indicator for nearby rides
              if (nearbyRidesCount > 0)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ).animate(onPlay: (c) => c.repeat())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.5, 1.5),
                            duration: 1000.ms,
                          )
                          .fadeOut(duration: 1000.ms),
                        const SizedBox(width: 4),
                        Text(
                          'Live',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Compact version for smaller spaces
class MapRibbonCompact extends StatelessWidget {
  final VoidCallback onTap;
  final int nearbyRidesCount;

  const MapRibbonCompact({
    super.key,
    required this.onTap,
    this.nearbyRidesCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Iconsax.map_1,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore Live Map',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (nearbyRidesCount > 0)
                    Text(
                      '$nearbyRidesCount rides available nearby',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.arrow_right_3,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}