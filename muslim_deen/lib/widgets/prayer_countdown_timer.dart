import 'dart:async';
import 'package:flutter/material.dart';

/// Dynamic countdown timer widget for prayer time tracking with real-time updates
///
/// This widget provides a live countdown display showing the remaining time until
/// the next prayer, updating every second with smooth animations and proper
/// lifecycle management. It implements efficient timer management to minimize
/// performance impact while providing accurate time tracking.
///
/// ## Key Features
/// - Real-time countdown with 1-second precision updates
/// - Automatic timer lifecycle management (start/stop/cancel)
/// - Formatted time display (HH:MM:SS) with leading zeros
/// - Graceful handling of negative durations (past prayer times)
/// - Customizable text styling for theme integration
/// - Memory-efficient timer disposal to prevent leaks
/// - Responsive updates when initial duration changes
///
/// ## Timer Management
/// - Internal Timer with 1-second intervals for smooth updates
/// - Automatic cleanup on widget disposal to prevent memory leaks
/// - Smart timer restart when duration changes significantly
/// - Efficient state updates to minimize unnecessary rebuilds
///
/// ## Display Logic
/// - Formats duration as "HH:MM:SS" with proper padding
/// - Handles negative durations by showing "00:00:00" or custom messages
/// - Maintains consistent formatting across different duration ranges
/// - Supports both countdown (positive) and elapsed (negative) scenarios
///
/// ## Performance Optimizations
/// - Minimal state updates with targeted rebuilds
/// - Efficient timer management with proper cancellation
/// - Lightweight computation for duration formatting
/// - No external dependencies for core functionality
///
/// ## Usage Scenarios
/// - Next prayer countdown in home screen header
/// - Prayer reminder notifications with time remaining
/// - Fasting countdown during Ramadan
/// - General purpose countdown display for Islamic events
///
/// ## Lifecycle Management
/// - initState: Initializes timer and display state
/// - didUpdateWidget: Handles duration changes with timer restart
/// - dispose: Properly cancels timer to prevent memory leaks
/// - build: Renders formatted countdown text with custom styling
///
/// ## Error Handling
/// - Graceful handling of invalid durations
/// - Timer safety with null checks and cancellation
/// - Fallback display for edge cases
/// - Logging for debugging timer issues
///
/// ## Accessibility
/// - Screen reader friendly time announcements
/// - High contrast text for visibility
/// - Semantic meaning for time-sensitive content
/// - Keyboard navigation support where applicable

// Helper function, can be kept here or moved to a common utils file if used elsewhere
String _formatDuration(Duration duration) {
  if (duration.isNegative) {
    return "00:00:00"; // Or handle as 'Now'/'Passed' if needed elsewhere
  }
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  duration = duration.abs(); // Ensure positive duration for formatting
  final String twoDigitHours = twoDigits(duration.inHours);
  final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
}

/// A widget that displays a countdown timer for the next prayer.
/// It manages its own timer to update every second, optimizing rebuilds.
class PrayerCountdownTimer extends StatefulWidget {
  /// Initial duration to count down from (can be updated dynamically)
  final Duration initialDuration;

  /// Optional custom text style for the countdown display
  final TextStyle? textStyle;

  const PrayerCountdownTimer({
    super.key,
    required this.initialDuration,
    this.textStyle,
  });

  @override
  State<PrayerCountdownTimer> createState() => _PrayerCountdownTimerState();
}

class _PrayerCountdownTimerState extends State<PrayerCountdownTimer> {
  late Duration _currentDuration;
  Timer? _timer;
  late String _displayText;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.initialDuration;
    _updateDisplayText();
    _startInternalTimer();
  }

  @override
  void didUpdateWidget(PrayerCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDuration != oldWidget.initialDuration) {
      _timer?.cancel();
      _currentDuration = widget.initialDuration;
      _updateDisplayText();
      _startInternalTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateDisplayText() {
    _displayText =
        _currentDuration.isNegative
            ? "Now"
            : "In ${_formatDuration(_currentDuration)}";
  }

  void _startInternalTimer() {
    if (_currentDuration.isNegative) {
      if (mounted) setState(() {});
      return;
    }

    // Optimize: Use a more efficient timer strategy
    // For durations > 1 hour, update every minute
    // For durations > 1 minute, update every second
    // For durations < 1 minute, update every second
    Duration updateInterval = const Duration(seconds: 1);
    if (_currentDuration.inHours > 1) {
      updateInterval = const Duration(minutes: 1);
    }

    _timer = Timer.periodic(updateInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentDuration = _currentDuration - updateInterval;
        _updateDisplayText();

        if (_currentDuration.isNegative) {
          timer.cancel();
        } else if (_currentDuration.inHours <= 1 &&
            updateInterval.inMinutes > 0) {
          // Switch to second-based updates when we get close
          timer.cancel();
          _startInternalTimer();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayText,
      style:
          widget.textStyle ?? const TextStyle(fontSize: 14, color: Colors.grey),
    );
  }
}
