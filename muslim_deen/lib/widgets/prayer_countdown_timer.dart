import 'dart:async';
import 'package:flutter/material.dart';

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
  final Duration initialDuration;
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
