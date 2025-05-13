import 'package:flutter/material.dart';

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
        _buildSkeletonBox(context, height: 24, width: 120),
        _buildSkeletonBox(context, height: 24, width: 100),
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
          _buildSkeletonBox(context, height: 20, width: 100),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSkeletonBox(context, height: 28, width: 80),
              _buildSkeletonBox(context, height: 28, width: 120),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrayerTimeSkeleton(BuildContext context) {
    return Row(
      children: [
        _buildSkeletonCircle(context, size: 40),
        const SizedBox(width: 16),
        _buildSkeletonBox(context, height: 20, width: 80),
        const Spacer(),
        _buildSkeletonBox(context, height: 20, width: 60),
      ],
    );
  }
  
  Widget _buildSkeletonBox(BuildContext context, {required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(102),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  Widget _buildSkeletonCircle(BuildContext context, {required double size}) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(102),
        shape: BoxShape.circle,
      ),
    );
  }
}
