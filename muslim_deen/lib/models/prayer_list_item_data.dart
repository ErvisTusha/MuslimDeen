import 'package:flutter/material.dart';

import 'package:muslim_deen/models/app_settings.dart' show PrayerNotification;

class PrayerListItemData {
  final String name;
  final DateTime? time;
  final PrayerNotification prayerEnum;
  final IconData iconData;

  PrayerListItemData({
    required this.name,
    this.time,
    required this.prayerEnum,
    required this.iconData,
  });
}
