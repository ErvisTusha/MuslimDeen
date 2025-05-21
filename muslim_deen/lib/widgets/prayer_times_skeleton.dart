import 'package:flutter/material.dart';
import 'package:muslim_deen/widgets/skeleton_primitives.dart';

/// A skeleton loader widget for prayer times
class PrayerTimesSkeleton extends StatelessWidget {
  const PrayerTimesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      children: [
        // Hijri date skeleton
        _buildDateSkeleton(context),
        const SizedBox(height: 24),
        
        // Next prayer skeleton
        _buildNextPrayerSkeleton(context),
        const SizedBox(height: 32),
        
        // Prayer times list skeleton
        ...List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildPrayerTimeSkeleton(context),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDateSkeleton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SkeletonBox(height: 24, width: 120),
        const SkeletonBox(height: 24, width: 100),
      ],
    );
  }
  
  Widget _buildNextPrayerSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(77),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(height: 20, width: 100),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(height: 28, width: 80),
              SkeletonBox(height: 28, width: 120),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrayerTimeSkeleton(BuildContext context) {
    return Row(
      children: [
        const SkeletonCircle(size: 40),
        const SizedBox(width: 16),
        const SkeletonBox(height: 20, width: 80),
        const Spacer(),
        const SkeletonBox(height: 20, width: 60),
      ],
    );
  }
}
