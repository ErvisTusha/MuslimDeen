import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

/// Types of Islamic events
enum IslamicEventType {
  holiday,        // Major Islamic holidays
  commemoration,  // Days of remembrance
  seasonal,       // Seasonal events
  historical,     // Historical Islamic events
  other,          // Other events
}

/// Categories for Islamic events
enum IslamicEventCategory {
  ramadan,        // Ramadan-related events
  eid,           // Eid celebrations
  prophets,      // Prophet-related events
  companions,    // Companion-related events
  general,       // General Islamic events
}

/// Represents an Islamic event or holiday
class IslamicEvent {
  final String id;
  final String title;
  final String description;
  final IslamicEventType type;
  final IslamicEventCategory category;
  final HijriCalendar hijriDate;  // Hijri date for the event
  final DateTime? gregorianDate;  // Calculated Gregorian date
  final bool isRecurring;         // Whether this event recurs annually
  final int? hijriDay;           // Specific hijri day (1-30)
  final int? hijriMonth;         // Specific hijri month (1-12)
  final bool isHoliday;           // Whether this is a holiday (no work/prayer changes)
  final String? fasting;          // Fasting requirements: 'obligatory', 'voluntary', 'none'
  final String? prayer;           // Special prayer requirements
  final String? significance;     // Religious significance
  final List<String> tags;        // Tags for filtering/searching

  IslamicEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.hijriDate,
    this.gregorianDate,
    this.isRecurring = true,
    this.hijriDay,
    this.hijriMonth,
    this.isHoliday = false,
    this.fasting,
    this.prayer,
    this.significance,
    this.tags = const [],
  });

  /// Create IslamicEvent from JSON
  factory IslamicEvent.fromJson(Map<String, dynamic> json) {
    return IslamicEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: IslamicEventType.values[json['type'] as int],
      category: IslamicEventCategory.values[json['category'] as int],
      hijriDate: HijriCalendar.fromDate(DateTime.parse(json['hijriDate'] as String)),
      gregorianDate: json['gregorianDate'] != null ? DateTime.parse(json['gregorianDate'] as String) : null,
      isRecurring: json['isRecurring'] as bool? ?? true,
      hijriDay: json['hijriDay'] as int?,
      hijriMonth: json['hijriMonth'] as int?,
      isHoliday: json['isHoliday'] as bool? ?? false,
      fasting: json['fasting'] as String?,
      prayer: json['prayer'] as String?,
      significance: json['significance'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Convert IslamicEvent to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'category': category.index,
      'hijriDate': hijriDate.toString(), // Use toString instead of gregorian()
      'gregorianDate': gregorianDate?.toIso8601String(),
      'isRecurring': isRecurring,
      'hijriDay': hijriDay,
      'hijriMonth': hijriMonth,
      'isHoliday': isHoliday,
      'fasting': fasting,
      'prayer': prayer,
      'significance': significance,
      'tags': tags,
    };
  }

  /// Create a copy with updated fields
  IslamicEvent copyWith({
    String? id,
    String? title,
    String? description,
    IslamicEventType? type,
    IslamicEventCategory? category,
    HijriCalendar? hijriDate,
    DateTime? gregorianDate,
    bool? isRecurring,
    int? hijriDay,
    int? hijriMonth,
    bool? isHoliday,
    String? fasting,
    String? prayer,
    String? significance,
    List<String>? tags,
  }) {
    return IslamicEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      hijriDate: hijriDate ?? this.hijriDate,
      gregorianDate: gregorianDate ?? this.gregorianDate,
      isRecurring: isRecurring ?? this.isRecurring,
      hijriDay: hijriDay ?? this.hijriDay,
      hijriMonth: hijriMonth ?? this.hijriMonth,
      isHoliday: isHoliday ?? this.isHoliday,
      fasting: fasting ?? this.fasting,
      prayer: prayer ?? this.prayer,
      significance: significance ?? this.significance,
      tags: tags ?? this.tags,
    );
  }

  /// Get the Gregorian date for a specific year
  DateTime getGregorianDateForYear(int year) {
    // For now, return approximate date - proper Hijri conversion needed
    if (hijriDay != null && hijriMonth != null) {
      return DateTime(year, hijriMonth!, hijriDay!);
    }
    return gregorianDate ?? DateTime(year, 1, 1);
  }

  /// Check if this event occurs on a specific Gregorian date
  bool occursOnDate(DateTime date) {
    if (gregorianDate != null) {
      return date.year == gregorianDate!.year &&
             date.month == gregorianDate!.month &&
             date.day == gregorianDate!.day;
    }

    final eventDate = getGregorianDateForYear(date.year);
    return date.year == eventDate.year &&
           date.month == eventDate.month &&
           date.day == eventDate.day;
  }

  /// Get display color based on event type
  Color get displayColor {
    switch (type) {
      case IslamicEventType.holiday:
        return Colors.green;
      case IslamicEventType.commemoration:
        return Colors.blue;
      case IslamicEventType.seasonal:
        return Colors.orange;
      case IslamicEventType.historical:
        return Colors.purple;
      case IslamicEventType.other:
        return Colors.grey;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IslamicEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'IslamicEvent(id: $id, title: $title, type: $type, category: $category, hijri: ${hijriDate.hDay}/${hijriDate.hMonth}/${hijriDate.hYear})';
  }
}

/// Collection of predefined Islamic events and holidays
class IslamicEventsDatabase {
  static final List<IslamicEvent> _events = [
    // Ramadan Events
    IslamicEvent(
      id: 'ramadan_start',
      title: 'Ramadan Begins',
      description: 'The start of the holy month of Ramadan',
      type: IslamicEventType.seasonal,
      category: IslamicEventCategory.ramadan,
      hijriDate: HijriCalendar.fromDate(DateTime(2024, 3, 11)), // Approximate date for Ramadan start
      isRecurring: true,
      hijriDay: 1,
      hijriMonth: 9,
      fasting: 'obligatory',
      significance: 'Month of fasting, prayer, and spiritual reflection',
      tags: ['ramadan', 'fasting', 'holy month'],
    ),

    IslamicEvent(
      id: 'laylatul_qadr',
      title: 'Laylatul Qadr (Night of Power)',
      description: 'The night when the Quran was first revealed',
      type: IslamicEventType.holiday,
      category: IslamicEventCategory.ramadan,
      hijriDate: HijriCalendar.fromDate(DateTime(2024, 4, 6)), // Approximate date for Laylatul Qadr
      isRecurring: true,
      hijriDay: 27,
      hijriMonth: 9,
      isHoliday: true,
      prayer: 'Special prayers and recitation',
      significance: 'Better than 1000 months of worship',
      tags: ['ramadan', 'qadr', 'holy night'],
    ),

    IslamicEvent(
      id: 'eid_ul_fitr',
      title: 'Eid ul-Fitr',
      description: 'Festival of Breaking the Fast',
      type: IslamicEventType.holiday,
      category: IslamicEventCategory.eid,
      hijriDate: HijriCalendar.fromDate(DateTime(2024, 4, 10)), // Approximate date for Eid ul-Fitr
      isRecurring: true,
      hijriDay: 1,
      hijriMonth: 10,
      isHoliday: true,
      fasting: 'none',
      prayer: 'Eid prayer',
      significance: 'Celebration marking the end of Ramadan',
      tags: ['eid', 'celebration', 'shawwal'],
    ),

    IslamicEvent(
      id: 'eid_ul_adha',
      title: 'Eid ul-Adha',
      description: 'Festival of Sacrifice',
      type: IslamicEventType.holiday,
      category: IslamicEventCategory.eid,
      hijriDate: HijriCalendar.fromDate(DateTime(2024, 6, 16)), // Approximate date for Eid ul-Adha
      isRecurring: true,
      hijriDay: 10,
      hijriMonth: 12,
      isHoliday: true,
      fasting: 'none',
      prayer: 'Eid prayer',
      significance: 'Commemorates Prophet Ibrahim\'s willingness to sacrifice his son',
      tags: ['eid', 'sacrifice', 'hajj'],
    ),

    // Prophet-related events
    IslamicEvent(
      id: 'isra_miraj',
      title: 'Isra and Miraj',
      description: 'Prophet Muhammad\'s night journey and ascension',
      type: IslamicEventType.commemoration,
      category: IslamicEventCategory.prophets,
      hijriDate: HijriCalendar.fromDate(DateTime(2024, 2, 14)), // Approximate date for Isra Miraj
      isRecurring: true,
      hijriDay: 27,
      hijriMonth: 7,
      significance: 'The Prophet\'s miraculous journey to Jerusalem and heaven',
      tags: ['prophet', 'miracle', 'jerusalem'],
    ),

    IslamicEvent(
      id: 'prophet_birthday',
      title: 'Mawlid al-Nabi',
      description: 'Birthday of Prophet Muhammad',
      type: IslamicEventType.commemoration,
      category: IslamicEventCategory.prophets,
      hijriDate: HijriCalendar.fromDate(DateTime(2023, 9, 27)), // Approximate date for Prophet's birthday
      isRecurring: true,
      hijriDay: 12,
      hijriMonth: 3,
      significance: 'Celebration of the Prophet\'s birth',
      tags: ['prophet', 'birthday', 'celebration'],
    ),

    // Other important dates
    IslamicEvent(
      id: 'ashura',
      title: 'Ashura',
      description: '10th of Muharram - Day of mourning and fasting',
      type: IslamicEventType.commemoration,
      category: IslamicEventCategory.general,
      hijriDate: HijriCalendar.fromDate(DateTime(2023, 7, 27)), // Approximate date for Ashura
      isRecurring: true,
      hijriDay: 10,
      hijriMonth: 1,
      fasting: 'voluntary',
      significance: 'Commemorates the martyrdom of Imam Hussain',
      tags: ['muharram', 'mourning', 'fasting'],
    ),

    IslamicEvent(
      id: 'first_revelation',
      title: 'First Revelation',
      description: 'The first revelation of the Quran to Prophet Muhammad',
      type: IslamicEventType.historical,
      category: IslamicEventCategory.prophets,
      hijriDate: HijriCalendar.fromDate(DateTime(610, 4, 6)), // First revelation date
      isRecurring: false,
      gregorianDate: DateTime(610, 4, 6), // Approximate Gregorian date
      significance: 'The beginning of the prophethood of Muhammad',
      tags: ['quran', 'revelation', 'prophet'],
    ),
  ];

  /// Get all predefined Islamic events
  static List<IslamicEvent> get allEvents => _events;

  /// Get events by type
  static List<IslamicEvent> getEventsByType(IslamicEventType type) {
    return _events.where((event) => event.type == type).toList();
  }

  /// Get events by category
  static List<IslamicEvent> getEventsByCategory(IslamicEventCategory category) {
    return _events.where((event) => event.category == category).toList();
  }

  /// Get events for a specific Hijri month
  static List<IslamicEvent> getEventsForHijriMonth(int month) {
    return _events.where((event) => event.hijriMonth == month).toList();
  }

  /// Get events occurring on a specific Gregorian date
  static List<IslamicEvent> getEventsForDate(DateTime date) {
    return _events.where((event) => event.occursOnDate(date)).toList();
  }

  /// Get holidays (events marked as holidays)
  static List<IslamicEvent> getHolidays() {
    return _events.where((event) => event.isHoliday).toList();
  }

  /// Search events by title or description
  static List<IslamicEvent> searchEvents(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _events.where((event) =>
      event.title.toLowerCase().contains(lowercaseQuery) ||
      event.description.toLowerCase().contains(lowercaseQuery) ||
      event.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }
}