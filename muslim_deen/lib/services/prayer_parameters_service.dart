import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service responsible for getting and configuring calculation parameters for prayer times.
class PrayerParametersService {
  final LoggerService _logger = locator<LoggerService>();

  /// Returns calculation parameters based on the provided settings.
  adhan.CalculationParameters getParameters(AppSettings settings) {
    final calculationMethod = settings.calculationMethod;
    final madhab = settings.madhab;

    adhan.CalculationParameters params;

    switch (calculationMethod) {
      case 'MuslimWorldLeague':
        params =
            adhan.CalculationMethod.muslimWorldLeague()
                as adhan.CalculationParameters;
        break;
      case 'NorthAmerica':
        params =
            adhan.CalculationMethod.northAmerica()
                as adhan.CalculationParameters;
        break;
      case 'Egyptian':
        params =
            adhan.CalculationMethod.egyptian() as adhan.CalculationParameters;
        break;
      case 'UmmAlQura':
        params =
            adhan.CalculationMethod.ummAlQura() as adhan.CalculationParameters;
        break;
      case 'Karachi':
        params =
            adhan.CalculationMethod.karachi() as adhan.CalculationParameters;
        break;
      case 'Tehran':
        params =
            adhan.CalculationMethod.tehran() as adhan.CalculationParameters;
        break;
      case 'Dubai':
        params = adhan.CalculationMethod.dubai() as adhan.CalculationParameters;
        break;
      case 'MoonsightingCommittee':
        params =
            adhan.CalculationMethod.moonsightingCommittee()
                as adhan.CalculationParameters;
        break;
      case 'Kuwait':
        params =
            adhan.CalculationMethod.kuwait() as adhan.CalculationParameters;
        break;
      case 'Qatar':
        params = adhan.CalculationMethod.qatar() as adhan.CalculationParameters;
        break;
      case 'Singapore':
        params =
            adhan.CalculationMethod.singapore() as adhan.CalculationParameters;
        break;
      case 'Turkey':
        _logger.warning(
          "Turkey calculation method falls back to MuslimWorldLeague in adhan_dart.",
        );
        params =
            adhan.CalculationMethod.muslimWorldLeague()
                as adhan.CalculationParameters;
        break;
      default:
        _logger.warning(
          "Unsupported calculation method '$calculationMethod', using MuslimWorldLeague.",
        );
        params =
            adhan.CalculationMethod.muslimWorldLeague()
                as adhan.CalculationParameters;
    }

    params.madhab =
        (madhab.toLowerCase() == 'hanafi')
            ? adhan.Madhab.hanafi
            : adhan.Madhab.shafi;
    params.highLatitudeRule = adhan.HighLatitudeRule.twilightAngle;

    return params;
  }
}
