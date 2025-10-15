import 'dart:math';
import 'package:flutter/material.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Represents a moon phase
enum MoonPhase {
  newMoon, // New Moon (conjunction)
  waxingCrescent, // Waxing Crescent
  firstQuarter, // First Quarter
  waxingGibbous, // Waxing Gibbous
  fullMoon, // Full Moon (opposition)
  waningGibbous, // Waning Gibbous
  lastQuarter, // Last Quarter
  waningCrescent, // Waning Crescent
}

/// Detailed moon phase information
class MoonPhaseInfo {
  final MoonPhase phase;
  final double illumination; // 0.0 to 1.0
  final DateTime date;
  final String phaseName;
  final String description;
  final IconData icon;

  MoonPhaseInfo({
    required this.phase,
    required this.illumination,
    required this.date,
    required this.phaseName,
    required this.description,
    required this.icon,
  });

  /// Get display color based on phase
  Color get displayColor {
    switch (phase) {
      case MoonPhase.newMoon:
        return Colors.grey.shade800;
      case MoonPhase.fullMoon:
        return Colors.yellow.shade200;
      case MoonPhase.firstQuarter:
      case MoonPhase.lastQuarter:
        return Colors.blue.shade200;
      case MoonPhase.waxingCrescent:
      case MoonPhase.waningCrescent:
        return Colors.blue.shade100;
      case MoonPhase.waxingGibbous:
      case MoonPhase.waningGibbous:
        return Colors.blue.shade300;
    }
  }

  @override
  String toString() {
    return 'MoonPhaseInfo(phase: $phaseName, illumination: ${(illumination * 100).toStringAsFixed(1)}%, date: $date)';
  }
}

/// Service for calculating moon phases and lunar information
class MoonPhasesService {
  final LoggerService _logger = locator<LoggerService>();

  // Astronomical constants
  static const double _newMoonJulianDate = 2451549.5; // J2000 epoch
  static const double _synodicMonth =
      29.53058867; // Average synodic month in days
  static const double _rad = pi / 180.0;

  bool _isInitialized = false;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    _isInitialized = true;
    _logger.info('MoonPhasesService initialized');
  }

  /// Calculate Julian date from DateTime
  double _julianDate(DateTime date) {
    final a = (14 - date.month) ~/ 12;
    final y = date.year + 4800 - a;
    final m = date.month + 12 * a - 3;

    return date.day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  /// Calculate moon phase for a given date
  MoonPhaseInfo calculateMoonPhase(DateTime date) {
    final julian = _julianDate(date);
    final daysSinceNewMoon = (julian - _newMoonJulianDate) % _synodicMonth;

    // Calculate phase angle
    final phaseAngle = (daysSinceNewMoon / _synodicMonth) * 360.0 * _rad;

    // Calculate illumination (simplified)
    final illumination = (1 + cos(phaseAngle)) / 2.0;

    // Determine phase
    final phase = _getMoonPhaseFromAngle(daysSinceNewMoon);

    return MoonPhaseInfo(
      phase: phase,
      illumination: illumination,
      date: date,
      phaseName: _getPhaseName(phase),
      description: _getPhaseDescription(phase),
      icon: _getPhaseIcon(phase),
    );
  }

  /// Get moon phase from days since new moon
  MoonPhase _getMoonPhaseFromAngle(double daysSinceNewMoon) {
    final phase = (daysSinceNewMoon / _synodicMonth) * 8.0;

    if (phase < 1) return MoonPhase.newMoon;
    if (phase < 2) return MoonPhase.waxingCrescent;
    if (phase < 3) return MoonPhase.firstQuarter;
    if (phase < 4) return MoonPhase.waxingGibbous;
    if (phase < 5) return MoonPhase.fullMoon;
    if (phase < 6) return MoonPhase.waningGibbous;
    if (phase < 7) return MoonPhase.lastQuarter;
    return MoonPhase.waningCrescent;
  }

  /// Get human-readable phase name
  String _getPhaseName(MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return 'New Moon';
      case MoonPhase.waxingCrescent:
        return 'Waxing Crescent';
      case MoonPhase.firstQuarter:
        return 'First Quarter';
      case MoonPhase.waxingGibbous:
        return 'Waxing Gibbous';
      case MoonPhase.fullMoon:
        return 'Full Moon';
      case MoonPhase.waningGibbous:
        return 'Waning Gibbous';
      case MoonPhase.lastQuarter:
        return 'Last Quarter';
      case MoonPhase.waningCrescent:
        return 'Waning Crescent';
    }
  }

  /// Get phase description
  String _getPhaseDescription(MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return 'The moon is between Earth and Sun, invisible from Earth';
      case MoonPhase.waxingCrescent:
        return 'A small crescent appears in the western sky after sunset';
      case MoonPhase.firstQuarter:
        return 'Half of the moon is illuminated, visible in the afternoon';
      case MoonPhase.waxingGibbous:
        return 'More than half illuminated, visible from afternoon to midnight';
      case MoonPhase.fullMoon:
        return 'The entire moon is illuminated, visible all night';
      case MoonPhase.waningGibbous:
        return 'More than half illuminated, visible from midnight to morning';
      case MoonPhase.lastQuarter:
        return 'Half of the moon is illuminated, visible in the morning';
      case MoonPhase.waningCrescent:
        return 'A small crescent appears in the eastern sky before sunrise';
    }
  }

  /// Get icon for phase
  IconData _getPhaseIcon(MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return Icons.brightness_2; // New moon
      case MoonPhase.waxingCrescent:
      case MoonPhase.waningCrescent:
        return Icons.brightness_3; // Crescent
      case MoonPhase.firstQuarter:
      case MoonPhase.lastQuarter:
        return Icons.brightness_4; // Half moon
      case MoonPhase.waxingGibbous:
      case MoonPhase.waningGibbous:
        return Icons.brightness_5; // Gibbous
      case MoonPhase.fullMoon:
        return Icons.brightness_7; // Full moon
    }
  }

  /// Get moon phase information for a date range
  List<MoonPhaseInfo> getMoonPhasesForRange(DateTime start, DateTime end) {
    final phases = <MoonPhaseInfo>[];
    var current = DateTime(start.year, start.month, start.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      phases.add(calculateMoonPhase(current));
      current = current.add(const Duration(days: 1));
    }

    return phases;
  }

  /// Get moon phases for a specific month
  Map<DateTime, String> getMoonPhasesForMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    final phases = <DateTime, String>{};
    final phaseInfos = getMoonPhasesForRange(startOfMonth, endOfMonth);

    for (final phaseInfo in phaseInfos) {
      // Only include significant phase changes (new moon, full moon, quarters)
      if (phaseInfo.phase == MoonPhase.newMoon ||
          phaseInfo.phase == MoonPhase.fullMoon ||
          phaseInfo.phase == MoonPhase.firstQuarter ||
          phaseInfo.phase == MoonPhase.lastQuarter) {
        phases[phaseInfo.date] = phaseInfo.phaseName;
      }
    }

    return phases;
  }

  /// Find next occurrence of a specific moon phase
  DateTime? findNextMoonPhase(MoonPhase targetPhase, {DateTime? fromDate}) {
    final start = fromDate ?? DateTime.now();
    var current = DateTime(start.year, start.month, start.day);

    // Search up to 60 days ahead
    for (int i = 0; i < 60; i++) {
      final phaseInfo = calculateMoonPhase(current);
      if (phaseInfo.phase == targetPhase) {
        return current;
      }
      current = current.add(const Duration(days: 1));
    }

    return null;
  }

  /// Get new moon dates for a month
  List<DateTime> getNewMoonsForMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    return getMoonPhasesForRange(startOfMonth, endOfMonth)
        .where((phase) => phase.phase == MoonPhase.newMoon)
        .map((phase) => phase.date)
        .toList();
  }

  /// Get full moon dates for a month
  List<DateTime> getFullMoonsForMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    return getMoonPhasesForRange(startOfMonth, endOfMonth)
        .where((phase) => phase.phase == MoonPhase.fullMoon)
        .map((phase) => phase.date)
        .toList();
  }

  /// Calculate Islamic month visibility (when moon should be visible)
  Map<String, dynamic> getIslamicMonthVisibility(DateTime date) {
    final phaseInfo = calculateMoonPhase(date);
    final hijriDay = _estimateHijriDay(date);

    // Moon visibility rules (simplified)
    final isVisible = phaseInfo.illumination > 0.02; // At least 2% illumination
    final visibility = _calculateVisibility(phaseInfo, date);

    return {
      'date': date,
      'hijriDay': hijriDay,
      'moonPhase': phaseInfo,
      'isVisible': isVisible,
      'visibility': visibility, // 'excellent', 'good', 'poor', 'invisible'
      'bestViewingTime': _getBestViewingTime(date, phaseInfo.phase),
    };
  }

  /// Estimate Hijri day (simplified calculation)
  int _estimateHijriDay(DateTime date) {
    // This is a simplified calculation. In reality, Islamic calendar
    // follows actual moon sightings, but this gives a reasonable approximation.
    final julian = _julianDate(date);
    final daysSinceNewMoon = (julian - _newMoonJulianDate) % _synodicMonth;
    return (daysSinceNewMoon.round() % 29) + 1;
  }

  /// Calculate visibility conditions
  String _calculateVisibility(MoonPhaseInfo phaseInfo, DateTime date) {
    final illumination = phaseInfo.illumination;

    // Consider time of year and weather (simplified)
    if (illumination < 0.02) return 'invisible';
    if (illumination < 0.1) return 'poor';
    if (illumination < 0.3) return 'good';
    return 'excellent';
  }

  /// Get best viewing time for moon
  String _getBestViewingTime(DateTime date, MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return 'Not visible';
      case MoonPhase.waxingCrescent:
      case MoonPhase.firstQuarter:
      case MoonPhase.waxingGibbous:
        return 'After sunset';
      case MoonPhase.fullMoon:
        return 'All night';
      case MoonPhase.waningGibbous:
      case MoonPhase.lastQuarter:
      case MoonPhase.waningCrescent:
        return 'Before sunrise';
    }
  }

  /// Get moon phase calendar for a month
  Map<DateTime, MoonPhaseInfo> getMoonPhaseCalendar(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    final phases = getMoonPhasesForRange(startOfMonth, endOfMonth);
    return {for (final phase in phases) phase.date: phase};
  }

  /// Get significant moon phase events for a month
  List<Map<String, dynamic>> getSignificantMoonEvents(int year, int month) {
    final events = <Map<String, dynamic>>[];

    final newMoons = getNewMoonsForMonth(year, month);
    final fullMoons = getFullMoonsForMonth(year, month);

    for (final newMoon in newMoons) {
      events.add({
        'date': newMoon,
        'type': 'new_moon',
        'title': 'New Moon',
        'description': 'Start of new Islamic month',
        'significance': 'high',
      });
    }

    for (final fullMoon in fullMoons) {
      events.add({
        'date': fullMoon,
        'type': 'full_moon',
        'title': 'Full Moon',
        'description': 'Moon is fully illuminated',
        'significance': 'medium',
      });
    }

    return events;
  }

  /// Dispose of resources
  void dispose() {
    _logger.info('MoonPhasesService disposed');
  }
}
