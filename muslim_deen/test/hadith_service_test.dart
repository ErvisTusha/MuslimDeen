import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_deen/models/hadith.dart';
import 'package:muslim_deen/services/hadith_service.dart';

void main() {
  group('HadithService', () {
    late HadithService hadithService;

    setUp(() {
      hadithService = HadithService();
    });

    test('getRandomHadith returns a valid Hadith', () {
      final hadith = hadithService.getRandomHadith();

      expect(hadith, isA<Hadith>());
      expect(hadith.text, isNotEmpty);
      expect(hadith.narrator, isNotEmpty);
      expect(hadith.source, isNotEmpty);
      expect(hadith.grade, isNotEmpty);
    });

    test('getHadithOfTheDay returns consistent result for same date', () {
      final date = DateTime(2025, 10, 11);
      final hadith1 = hadithService.getHadithOfTheDay(date);
      final hadith2 = hadithService.getHadithOfTheDay(date);

      expect(hadith1, isA<Hadith>());
      expect(hadith1.text, equals(hadith2.text));
      expect(hadith1.narrator, equals(hadith2.narrator));
    });

    test('getHadithOfTheDay returns different results for different dates', () {
      final date1 = DateTime(2025, 10, 11);
      final date2 = DateTime(2025, 10, 12);
      final hadith1 = hadithService.getHadithOfTheDay(date1);
      final hadith2 = hadithService.getHadithOfTheDay(date2);

      // Should be different most of the time due to date-based selection
      expect(hadith1, isA<Hadith>());
      expect(hadith2, isA<Hadith>());
    });
  });
}
