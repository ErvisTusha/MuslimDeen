import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_deen/services/country_calculation_service.dart';

void main() {
  group('CountryCalculationService Tests', () {
    test('should return correct calculation methods for different countries', () {
      expect(CountryCalculationService.getCalculationMethodForCountry('TR'), 'Turkey');
      expect(CountryCalculationService.getCalculationMethodForCountry('EG'), 'Egyptian');
      expect(CountryCalculationService.getCalculationMethodForCountry('DZ'), 'Egyptian');
      expect(CountryCalculationService.getCalculationMethodForCountry('MA'), 'Morocco');
      expect(CountryCalculationService.getCalculationMethodForCountry('AL'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('SA'), 'UmmAlQura');
      expect(CountryCalculationService.getCalculationMethodForCountry('AE'), 'Dubai');
      expect(CountryCalculationService.getCalculationMethodForCountry('IR'), 'Tehran');
      expect(CountryCalculationService.getCalculationMethodForCountry('PK'), 'Karachi');
      expect(CountryCalculationService.getCalculationMethodForCountry('US'), 'MuslimWorldLeague');
    });

    test('should return default method for unsupported country codes', () {
      expect(CountryCalculationService.getCalculationMethodForCountry('XX'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry(''), 'MuslimWorldLeague');
    });

    test('should handle case insensitive country codes', () {
      expect(CountryCalculationService.getCalculationMethodForCountry('tr'), 'Turkey');
      expect(CountryCalculationService.getCalculationMethodForCountry('TR'), 'Turkey');
      expect(CountryCalculationService.getCalculationMethodForCountry('Tr'), 'Turkey');
    });

    test('should return method ID for Aladhan API', () {
      expect(CountryCalculationService.getMethodIdForCountry('TR'), 0);
      expect(CountryCalculationService.getMethodIdForCountry('EG'), 5);
      expect(CountryCalculationService.getMethodIdForCountry('SA'), 3);
      expect(CountryCalculationService.getMethodIdForCountry('AE'), 8);
      expect(CountryCalculationService.getMethodIdForCountry('KW'), 9);
      expect(CountryCalculationService.getMethodIdForCountry('QA'), 10);
      expect(CountryCalculationService.getMethodIdForCountry('IR'), 7);
      expect(CountryCalculationService.getMethodIdForCountry('US'), 3); // Default
    });

    test('should return all supported countries', () {
      final countries = CountryCalculationService.getAllSupportedCountries();
      expect(countries.isNotEmpty, true);
      expect(countries.containsKey('TR'), true);
      expect(countries.containsKey('EG'), true);
      expect(countries.containsKey('DZ'), true);
      expect(countries.containsKey('MA'), true);
    });

    test('should have specific calculation methods for Balkan countries', () {
      expect(CountryCalculationService.getCalculationMethodForCountry('AL'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('RS'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('BA'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('MK'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('ME'), 'MuslimWorldLeague');
    });

    test('should have proper mapping for Middle Eastern countries', () {
      expect(CountryCalculationService.getCalculationMethodForCountry('IQ'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('SY'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('JO'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('LB'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('YE'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('SD'), 'MuslimWorldLeague');
    });

    test('should have proper mapping for North African countries', () {
      expect(CountryCalculationService.getCalculationMethodForCountry('TN'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('LY'), 'MuslimWorldLeague');
    });

    test('should have proper mapping for Asian countries', () {
      expect(CountryCalculationService.getCalculationMethodForCountry('IN'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('BD'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('ID'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('MY'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('AF'), 'MuslimWorldLeague');
    });

    test('should have proper mapping for Central Asian countries', () {
      expect(CountryCalculationService.getCalculationMethodForCountry('UZ'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('KZ'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('KG'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('TJ'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('TM'), 'MuslimWorldLeague');
      expect(CountryCalculationService.getCalculationMethodForCountry('AZ'), 'MuslimWorldLeague');
    });
  });
}
