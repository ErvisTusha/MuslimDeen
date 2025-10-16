import 'dart:math';
import 'package:flutter/material.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Represents a moon phase
/// 
/// Enumeration of the eight primary moon phases in the lunar cycle.
/// These phases are used to track the Islamic calendar which is based
/// on lunar observations.
enum MoonPhase {
  /// New Moon (conjunction) - Moon is between Earth and Sun
  newMoon,
  
  /// Waxing Crescent - First visible sliver after new moon
  waxingCrescent,
  
  /// First Quarter - Half illuminated, waxing
  firstQuarter,
  
  /// Waxing Gibbous - More than half illuminated, waxing
  waxingGibbous,
  
  /// Full Moon (opposition) - Fully illuminated
  fullMoon,
  
  /// Waning Gibbous - More than half illuminated, waning
  waningGibbous,
  
  /// Last Quarter - Half illuminated, waning
  lastQuarter,
  
  /// Waning Crescent - Last visible sliver before new moon
  waningCrescent,
}

/// Detailed moon phase information
/// 
/// This class encapsulates comprehensive information about a moon phase
/// for a specific date, including illumination percentage, visual
/// representation, and contextual information.
/// 
/// Usage:
/// ```dart
/// final phaseInfo = MoonPhaseInfo(
///   phase: MoonPhase.fullMoon,
///   illumination: 1.0,
///   date: DateTime.now(),
///   phaseName: 'Full Moon',
///   description: 'The entire moon is illuminated',
///   icon: Icons.brightness_7,
/// );
/// ```
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
  /// 
  /// Returns an appropriate color for displaying the moon phase
  /// in the UI, with darker colors for new moon and brighter
  /// colors for full moon.
  /// 
  /// Returns:
  /// - Color appropriate for the moon phase
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
/// 
/// This service provides comprehensive functionality for calculating moon phases,
/// lunar illumination, and related astronomical information. It uses mathematical
/// algorithms to determine moon phases without requiring external APIs.
/// 
/// Features:
/// - Calculate moon phases for any date
/// - Determine moon illumination percentage
/// - Find next occurrence of specific moon phases
/// - Calculate Islamic month visibility
/// - Generate moon phase calendars
/// - Provide viewing recommendations
/// 
/// Usage:
/// ```dart
/// final moonService = MoonPhasesService();
/// await moonService.init();
/// final todayPhase = moonService.calculateMoonPhase(DateTime.now());
/// final nextFullMoon = moonService.findNextMoonPhase(MoonPhase.fullMoon);
/// ```
/// 
/// Design Patterns:
/// - Calculator: Encapsulates astronomical calculations
/// - Factory: Creates MoonPhaseInfo objects
/// - Strategy: Different calculation methods for different needs
/// 
/// Performance Considerations:
/// - Pure mathematical calculations, no external dependencies
/// - Efficient algorithms for phase determination
/// - Minimal memory footprint
/// 
/// Dependencies:
/// - LoggerService: For centralized logging
/// 
/// Note:
/// The calculations use simplified algorithms that provide good approximations
/// for most practical purposes. For precise astronomical applications,
/// more complex algorithms would be required.
class MoonPhasesService {
  final LoggerService _logger = locator<LoggerService>();

  // Astronomical constants
  static const double _newMoonJulianDate = 2451549.5; // J2000 epoch
  static const double _synodicMonth =
      29.53058867; // Average synodic month in days
  static const double _rad = pi / 180.0;

  bool _isInitialized = false;

  /// Initialize the service
  /// 
  /// Initializes the moon phases service. This is a lightweight operation
  /// that sets up the service for use. The service doesn't require
  /// external resources or complex initialization.
  /// 
  /// Performance:
  /// - Very fast initialization
  /// - No external dependencies
  /// - Safe to call multiple times
  Future<void> init() async {
    if (_isInitialized) return;

    _isInitialized = true;
    _logger.info('MoonPhasesService initialized');
  }

  /// Calculate Julian date from DateTime
  /// 
  /// Converts a Gregorian DateTime to a Julian date, which is used
  /// for astronomical calculations. The Julian date is a continuous
  /// count of days since noon Universal Time on January 1, 4713 BCE.
  /// 
  /// Parameters:
  /// - [date]: The Gregorian date to convert
  /// 
  /// Algorithm:
  /// Uses the standard algorithm for Gregorian to Julian date conversion
  /// with proper handling of leap years and month adjustments.
  /// 
  /// Returns:
  /// - Julian date as a double
  /// 
  /// Note:
  /// This algorithm is valid for Gregorian calendar dates on or after
  /// 1582-10-15. For earlier dates, the Julian calendar algorithm would be needed.
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
  /// 
  /// Determines the moon phase and illumination for a specific date
  /// using astronomical calculations based on the synodic month.
  /// 
  /// Parameters:
  /// - [date]: The date to calculate the moon phase for
  /// 
  /// Algorithm:
  /// 1. Convert date to Julian date
  /// 2. Calculate days since known new moon
  /// 3. Determine phase angle based on synodic month
  /// 4. Calculate illumination using cosine function
  /// 5. Determine specific moon phase from angle
  /// 
  /// Performance:
  /// - O(1) complexity, very fast calculation
  /// - No external dependencies
  /// 
  /// Returns:
  /// - MoonPhaseInfo with comprehensive phase information
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
  /// 
  /// Determines the specific moon phase based on the number of days
  /// since the last new moon. The synodic month is divided into 8
  /// equal parts, each representing a primary moon phase.
  /// 
  /// Parameters:
  /// - [daysSinceNewMoon]: Days elapsed since the last new moon
  /// 
  /// Algorithm:
  /// 1. Calculate phase number (0-7) based on days since new moon
  /// 2. Map phase number to MoonPhase enum
  /// 
  /// Returns:
  /// - The corresponding MoonPhase enum value
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
  /// 
  /// Returns the common English name for a moon phase.
  /// This is used for display purposes in the UI.
  /// 
  /// Parameters:
  /// - [phase]: The moon phase enum value
  /// 
  /// Returns:
  /// - Human-readable phase name
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
  /// 
  /// Returns a descriptive explanation of the moon phase,
  /// including visibility information and general characteristics.
  /// 
  /// Parameters:
  /// - [phase]: The moon phase enum value
  /// 
  /// Returns:
  /// - Detailed description of the moon phase
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
  /// 
  /// Returns an appropriate Material Design icon for representing
  /// the moon phase in the UI.
  /// 
  /// Parameters:
  /// - [phase]: The moon phase enum value
  /// 
  /// Returns:
  /// - IconData representing the moon phase
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
  /// 
  /// Calculates moon phase information for each day in a date range.
  /// This is useful for creating moon phase calendars or displays.
  /// 
  /// Parameters:
  /// - [start]: The start date of the range
  /// - [end]: The end date of the range
  /// 
  /// Algorithm:
  /// 1. Iterate through each day in the range
  /// 2. Calculate moon phase for each day
  /// 3. Collect results in a list
  /// 
  /// Performance:
  /// - O(n) where n is the number of days in the range
  /// - Each calculation is O(1)
  /// 
  /// Returns:
  /// - List of MoonPhaseInfo for each day in the range
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
  /// 
  /// Returns significant moon phases (new moon, full moon, quarters)
  /// for a specific month. This is useful for highlighting important
  /// lunar events in calendar displays.
  /// 
  /// Parameters:
  /// - [year]: The year
  /// - [month]: The month (1-12)
  /// 
  /// Algorithm:
  /// 1. Calculate phases for the entire month
  /// 2. Filter for significant phases only
  /// 3. Return map of dates to phase names
  /// 
  /// Returns:
  /// - Map of dates to significant moon phase names
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
  /// 
  /// Searches forward from a given date to find the next occurrence
  /// of a specific moon phase. This is useful for planning future
  /// observations or events related to specific lunar phases.
  /// 
  /// Parameters:
  /// - [targetPhase]: The moon phase to search for
  /// - [fromDate]: The date to start searching from (default: now)
  /// 
  /// Algorithm:
  /// 1. Start from the given date (or now)
  /// 2. Check each day sequentially
  /// 3. Return the first matching date
  /// 4. Limit search to 60 days for performance
  /// 
  /// Performance:
  /// - O(n) where n is the number of days until the phase
  /// - Worst case: 60 iterations
  /// 
  /// Returns:
  /// - Date of next occurrence, or null if not found within 60 days
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
  /// 
  /// Returns all dates in a month when a new moon occurs.
  /// New moons are significant for Islamic calendar calculations.
  /// 
  /// Parameters:
  /// - [year]: The year
  /// - [month]: The month (1-12)
  /// 
  /// Returns:
  /// - List of dates when new moon occurs
  List<DateTime> getNewMoonsForMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    return getMoonPhasesForRange(startOfMonth, endOfMonth)
        .where((phase) => phase.phase == MoonPhase.newMoon)
        .map((phase) => phase.date)
        .toList();
  }

  /// Get full moon dates for a month
  /// 
  /// Returns all dates in a month when a full moon occurs.
  /// Full moons are significant for various Islamic observances.
  /// 
  /// Parameters:
  /// - [year]: The year
  /// - [month]: The month (1-12)
  /// 
  /// Returns:
  /// - List of dates when full moon occurs
  List<DateTime> getFullMoonsForMonth(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    return getMoonPhasesForRange(startOfMonth, endOfMonth)
        .where((phase) => phase.phase == MoonPhase.fullMoon)
        .map((phase) => phase.date)
        .toList();
  }

  /// Calculate Islamic month visibility (when moon should be visible)
  /// 
  /// Calculates moon visibility information for Islamic calendar purposes.
  /// This helps determine when a new Islamic month begins based on
  /// moon visibility criteria.
  /// 
  /// Parameters:
  /// - [date]: The date to check visibility for
  /// 
  /// Algorithm:
  /// 1. Calculate moon phase and illumination
  /// 2. Estimate Hijri day
  /// 3. Determine visibility based on illumination
  /// 4. Calculate visibility quality
  /// 5. Determine best viewing time
  /// 
  /// Returns:
  /// - Map containing comprehensive visibility information
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
  /// 
  /// Estimates the Hijri day based on moon phase calculations.
  /// This is a simplified calculation that provides a reasonable
  /// approximation for most purposes.
  /// 
  /// Parameters:
  /// - [date]: The Gregorian date
  /// 
  /// Note:
  /// In reality, the Islamic calendar follows actual moon sightings,
  /// which can vary by location and atmospheric conditions.
  /// 
  /// Returns:
  /// - Estimated Hijri day number (1-29)
  int _estimateHijriDay(DateTime date) {
    // This is a simplified calculation. In reality, Islamic calendar
    // follows actual moon sightings, but this gives a reasonable approximation.
    final julian = _julianDate(date);
    final daysSinceNewMoon = (julian - _newMoonJulianDate) % _synodicMonth;
    return (daysSinceNewMoon.round() % 29) + 1;
  }

  /// Calculate visibility conditions
  /// 
  /// Determines the quality of moon visibility based on illumination
  /// and other factors. This helps users understand how easily
  /// the moon can be observed.
  /// 
  /// Parameters:
  /// - [phaseInfo]: The moon phase information
  /// - [date]: The date of observation
  /// 
  /// Returns:
  /// - Visibility quality rating string
  String _calculateVisibility(MoonPhaseInfo phaseInfo, DateTime date) {
    final illumination = phaseInfo.illumination;

    // Consider time of year and weather (simplified)
    if (illumination < 0.02) return 'invisible';
    if (illumination < 0.1) return 'poor';
    if (illumination < 0.3) return 'good';
    return 'excellent';
  }

  /// Get best viewing time for moon
  /// 
  /// Provides recommendations for the best time to observe the moon
  /// based on its phase. This helps users plan their observations.
  /// 
  /// Parameters:
  /// - [date]: The date of observation
  /// - [phase]: The moon phase
  /// 
  /// Returns:
  /// - String describing the best viewing time
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
  /// 
  /// Generates a complete moon phase calendar for a month,
  /// with phase information for each day.
  /// 
  /// Parameters:
  /// - [year]: The year
  /// - [month]: The month (1-12)
  /// 
  /// Returns:
  /// - Map of dates to moon phase information
  Map<DateTime, MoonPhaseInfo> getMoonPhaseCalendar(int year, int month) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    final phases = getMoonPhasesForRange(startOfMonth, endOfMonth);
    return {for (final phase in phases) phase.date: phase};
  }

  /// Get significant moon phase events for a month
  /// 
  /// Returns a list of significant lunar events for a month,
  /// with context about their significance for Islamic observations.
  /// 
  /// Parameters:
  /// - [year]: The year
  /// - [month]: The month (1-12)
  /// 
  /// Returns:
  /// - List of significant moon events with descriptions
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
  /// 
  /// Cleans up resources when the service is no longer needed.
  /// This service has minimal resources to clean up.
  void dispose() {
    _logger.info('MoonPhasesService disposed');
  }
}