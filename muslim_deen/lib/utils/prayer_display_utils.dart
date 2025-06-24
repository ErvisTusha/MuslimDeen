import 'package:flutter/material.dart';
import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/models/prayer_display_info_data.dart';
import 'package:adhan_dart/adhan_dart.dart' as adhan;

typedef GetOffsettedTimeFunc = DateTime? Function(
  String prayerName,
  adhan.PrayerTimes prayerTimes,
  AppSettings settings,
);

PrayerDisplayInfoData getPrayerDisplayInfo({
  required PrayerNotification prayerEnum,
  required adhan.PrayerTimes? prayerTimes,
  required AppSettings appSettings,
  required GetOffsettedTimeFunc getOffsettedTime,
}) {
  DateTime? time;
  IconData icon;

  if (prayerTimes == null) {
    return PrayerDisplayInfoData(
      name: prayerEnum.displayName,
      time: null,
      prayerEnum: prayerEnum,
      iconData: Icons.error_outline,
    );
  }

  String prayerNameKey; // To pass to getOffsettedTime

  switch (prayerEnum) {
    case PrayerNotification.fajr:
      prayerNameKey = "fajr";
      icon = Icons.wb_sunny_outlined; // Dawn/Sunrise icon
      break;
    case PrayerNotification.sunrise:
      prayerNameKey = "sunrise";
      icon = Icons.wb_twilight_outlined; // Sunrise icon
      break;
    case PrayerNotification.dhuhr:
      prayerNameKey = "dhuhr";
      icon = Icons.wb_sunny; // Midday sun
      break;
    case PrayerNotification.asr:
      prayerNameKey = "asr";
      icon = Icons.wb_twilight; // Afternoon/twilight
      break;
    case PrayerNotification.maghrib:
      prayerNameKey = "maghrib";
      icon = Icons.brightness_4_outlined; // Sunset icon
      break;
    case PrayerNotification.isha:
      prayerNameKey = "isha";
      icon = Icons.nights_stay; // Moon/night icon
      break;
  }
  time = getOffsettedTime(prayerNameKey, prayerTimes, appSettings);

  return PrayerDisplayInfoData(
    name: prayerEnum.displayName,
    time: time,
    prayerEnum: prayerEnum,
    iconData: icon,
  );
}
