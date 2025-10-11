import 'dart:math';

import 'package:muslim_deen/models/hadith.dart';

class HadithService {
  static final List<Hadith> _hadiths = [
    const Hadith(
      text: "Actions are judged by intentions.",
      narrator: "Umar ibn al-Khattab",
      source: "Sahih al-Bukhari",
      grade: "Sahih",
    ),
    const Hadith(
      text:
          "The strong is not the one who overcomes the people by his strength, but the strong is the one who controls himself while in anger.",
      narrator: "Prophet Muhammad",
      source: "Sahih al-Bukhari",
      grade: "Sahih",
    ),
    const Hadith(
      text:
          "None of you truly believes until he loves for his brother what he loves for himself.",
      narrator: "Prophet Muhammad",
      source: "Sahih al-Bukhari",
      grade: "Sahih",
    ),
    const Hadith(
      text:
          "The best among you are those who have the best manners and character.",
      narrator: "Prophet Muhammad",
      source: "Sunan al-Tirmidhi",
      grade: "Hasan",
    ),
    const Hadith(
      text:
          "Whoever believes in Allah and the Last Day should speak good or remain silent.",
      narrator: "Prophet Muhammad",
      source: "Sahih al-Bukhari",
      grade: "Sahih",
    ),
  ];

  Hadith getRandomHadith() {
    final random = Random();
    return _hadiths[random.nextInt(_hadiths.length)];
  }

  Hadith getHadithOfTheDay(DateTime date) {
    // Use date to get consistent hadith for the day
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return _hadiths[dayOfYear % _hadiths.length];
  }
}
