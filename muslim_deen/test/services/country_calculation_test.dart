import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_deen/services/country_calculation_service.dart';

void main() {
  group('CountryCalculationService Tests', () {
    test('Should return correct calculation method for known countries', () {
      expect(
        CountryCalculationService.getCalculationMethodForCountry('TR'),
        'Turkey',
      );
      expect(
        CountryCalculationService.getCalculationMethodForCountry('EG'),
        'Egyptian',
      );
      expect(
        CountryCalculationService.getCalculationMethodForCountry('SA'),
        'UmmAlQura',
      );
      expect(
        CountryCalculationService.getCalculationMethodForCountry('PK'),
        'Karachi',
      );
      expect(
        CountryCalculationService.getCalculationMethodForCountry('IR'),
        'Tehran',
      );
      expect(
        CountryCalculationService.getCalculationMethodForCountry('AE'),
        'Dubai',
      );
    });

    test('Should fallback to MuslimWorldLeague for unknown countries', () {
      expect(
        CountryCalculationService.getCalculationMethodForCountry('XX'),
        'MuslimWorldLeague',
      );
      expect(
        CountryCalculationService.getCalculationMethodForCountry(''),
        'MuslimWorldLeague',
      );
    });

    test('Should return correct method ID for Aladhan API', () {
      expect(CountryCalculationService.getMethodIdForCountry('TR'), 0);
      expect(CountryCalculationService.getMethodIdForCountry('EG'), 5);
      expect(CountryCalculationService.getMethodIdForCountry('SA'), 3);
      expect(CountryCalculationService.getMethodIdForCountry('AE'), 8);
      expect(CountryCalculationService.getMethodIdForCountry('KW'), 9);
      expect(CountryCalculationService.getMethodIdForCountry('QA'), 10);
      expect(CountryCalculationService.getMethodIdForCountry('IR'), 7);

      // Default/Fallback
      expect(CountryCalculationService.getMethodIdForCountry('AL'), 3);
      expect(CountryCalculationService.getMethodIdForCountry('XX'), 3);
    });

    test('getAllSupportedCountries should return the complete map', () {
      final countries = CountryCalculationService.getAllSupportedCountries();
      expect(countries.containsKey('TR'), true);
      expect(countries.containsKey('US'), false); // Not in the static map
      expect(countries['BA'], 'MuslimWorldLeague');
    });
  });
}
