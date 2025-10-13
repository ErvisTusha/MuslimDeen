import 'dart:async';
import 'dart:convert';

import 'package:muslim_deen/models/zakat.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/storage_service.dart';

/// Service for calculating Zakat and managing Zakat-related data
class ZakatCalculatorService {
  final StorageService _storageService;
  final LoggerService _logger = locator<LoggerService>();

  static const String _zakatInputKey = 'zakat_input';
  static const String _zakatHistoryKey = 'zakat_history';

  // Current market prices (should be updated regularly)
  double _goldPricePerGram = 60.0; // USD per gram
  double _silverPricePerGram = 0.7; // USD per gram

  bool _isInitialized = false;

  ZakatCalculatorService(this._storageService);

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _loadMarketPrices();
      _isInitialized = true;
      _logger.info('ZakatCalculatorService initialized');
    } catch (e, s) {
      _logger.error('Failed to initialize ZakatCalculatorService', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Load current market prices (in a real app, this would fetch from an API)
  Future<void> _loadMarketPrices() async {
    // For now, use default values. In production, this would fetch from a financial API
    _goldPricePerGram = 60.0; // Approximate current price
    _silverPricePerGram = 0.7;  // Approximate current price

    _logger.debug('Market prices loaded', data: {
      'goldPerGram': _goldPricePerGram,
      'silverPerGram': _silverPricePerGram,
    });
  }

  /// Update market prices
  Future<void> updateMarketPrices(double goldPricePerGram, double silverPricePerGram) async {
    _goldPricePerGram = goldPricePerGram;
    _silverPricePerGram = silverPricePerGram;

    _logger.info('Market prices updated', data: {
      'goldPerGram': _goldPricePerGram,
      'silverPerGram': _silverPricePerGram,
    });
  }

  /// Calculate Zakat based on input data
  Future<ZakatCalculation> calculateZakat(ZakatInput input) async {
    await init();

    final nisabValue = ZakatInfo.calculateNisab(
      goldPricePerGram: _goldPricePerGram,
      silverPricePerGram: _silverPricePerGram,
      useGold: true, // Default to gold-based Nisab
    );

    final calculation = ZakatCalculation.calculate(
      assets: input.assets,
      liabilities: input.liabilities,
      nisabThreshold: nisabValue,
    );

    // Save the input for future reference
    await saveZakatInput(input);

    // Record the calculation in history
    await _recordCalculation(calculation);

    _logger.info('Zakat calculated', data: {
      'totalAssets': calculation.totalAssets,
      'netAssets': calculation.netAssets,
      'zakatAmount': calculation.zakatAmount,
      'isDue': calculation.isZakatDue,
    });

    return calculation;
  }

  /// Save Zakat input data
  Future<void> saveZakatInput(ZakatInput input) async {
    try {
      await _storageService.saveData(_zakatInputKey, jsonEncode(input.toJson()));

      _logger.debug('Zakat input saved');
    } catch (e, s) {
      _logger.error('Failed to save Zakat input', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Load saved Zakat input data
  Future<ZakatInput?> loadZakatInput() async {
    try {
      final inputJson = await _storageService.getData(_zakatInputKey) as String?;
      if (inputJson != null) {
        final inputData = jsonDecode(inputJson) as Map<String, dynamic>;
        return ZakatInput.fromJson(inputData);
      }
      return null;
    } catch (e, s) {
      _logger.error('Failed to load Zakat input', error: e, stackTrace: s);
      return null;
    }
  }

  /// Record a calculation in history
  Future<void> _recordCalculation(ZakatCalculation calculation) async {
    try {
      final history = await _loadCalculationHistory();
      history.add(calculation);

      // Keep only last 50 calculations
      if (history.length > 50) {
        history.removeRange(0, history.length - 50);
      }

      await _storageService.saveData(_zakatHistoryKey, jsonEncode(history.map((h) => h.toJson()).toList()));

      _logger.debug('Calculation recorded in history');
    } catch (e, s) {
      _logger.error('Failed to record calculation', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Load calculation history
  Future<List<ZakatCalculation>> _loadCalculationHistory() async {
    try {
      final historyJson = _storageService.getData(_zakatHistoryKey) as String?;
      if (historyJson != null) {
        final historyData = jsonDecode(historyJson) as List<dynamic>;
        return historyData.map((c) => _calculationFromJson(c as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, s) {
      _logger.error('Failed to load calculation history', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get calculation history
  Future<List<ZakatCalculation>> getCalculationHistory({int limit = 10}) async {
    final history = await _loadCalculationHistory();
    history.sort((a, b) => b.calculationDate.compareTo(a.calculationDate));
    return history.take(limit).toList();
  }

  /// Convert JSON to calculation
  ZakatCalculation _calculationFromJson(Map<String, dynamic> json) {
    return ZakatCalculation(
      totalAssets: json['totalAssets'] as double,
      totalLiabilities: json['totalLiabilities'] as double,
      netAssets: json['netAssets'] as double,
      zakatAmount: json['zakatAmount'] as double,
      nisabThreshold: json['nisabThreshold'] as double,
      isZakatDue: json['isZakatDue'] as bool,
      calculationDate: DateTime.parse(json['calculationDate'] as String),
      assetBreakdown: (json['assetBreakdown'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(ZakatAssetType.values[int.parse(key)], value as double),
      ),
      liabilityBreakdown: (json['liabilityBreakdown'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as double),
      ),
    );
  }

  /// Get current Nisab value
  double getCurrentNisab({bool useGold = true}) {
    return ZakatInfo.calculateNisab(
      goldPricePerGram: _goldPricePerGram,
      silverPricePerGram: _silverPricePerGram,
      useGold: useGold,
    );
  }

  /// Get Zakat due date information
  Map<String, dynamic> getZakatDueInfo(DateTime lastPayment) {
    final isYearComplete = ZakatInfo.isZakatYearComplete(lastPayment);
    final nextDueDate = lastPayment.add(Duration(days: (ZakatInfo.lunarMonths * 29.5).round()));

    return {
      'isYearComplete': isYearComplete,
      'nextDueDate': nextDueDate,
      'daysUntilDue': nextDueDate.difference(DateTime.now()).inDays,
      'lastPayment': lastPayment,
    };
  }

  /// Get detailed breakdown of Zakat calculation
  Map<String, dynamic> getDetailedBreakdown(ZakatCalculation calculation) {
    final assetDetails = <Map<String, dynamic>>[];
    final liabilityDetails = <Map<String, dynamic>>[];

    calculation.assetBreakdown.forEach((type, amount) {
      if (amount > 0) {
        final zakatOnAsset = amount * ZakatInfo.zakatRate;
        assetDetails.add({
          'type': type,
          'typeName': _getAssetTypeName(type),
          'amount': amount,
          'zakatAmount': zakatOnAsset,
          'info': ZakatInfo.getAssetTypeInfo(type),
        });
      }
    });

    calculation.liabilityBreakdown.forEach((name, amount) {
      if (amount > 0) {
        liabilityDetails.add({
          'name': name,
          'amount': amount,
        });
      }
    });

    return {
      'assets': assetDetails,
      'liabilities': liabilityDetails,
      'summary': {
        'totalAssets': calculation.totalAssets,
        'totalLiabilities': calculation.totalLiabilities,
        'netAssets': calculation.netAssets,
        'nisabThreshold': calculation.nisabThreshold,
        'zakatAmount': calculation.zakatAmount,
        'isZakatDue': calculation.isZakatDue,
      },
    };
  }

  /// Get human-readable asset type name
  String _getAssetTypeName(ZakatAssetType type) {
    switch (type) {
      case ZakatAssetType.cash:
        return 'Cash & Savings';
      case ZakatAssetType.gold:
        return 'Gold & Jewelry';
      case ZakatAssetType.silver:
        return 'Silver';
      case ZakatAssetType.stocks:
        return 'Stocks & Investments';
      case ZakatAssetType.business:
        return 'Business Assets';
      case ZakatAssetType.livestock:
        return 'Livestock';
      case ZakatAssetType.agriculture:
        return 'Agricultural Produce';
      case ZakatAssetType.other:
        return 'Other Assets';
    }
  }

  /// Clear all Zakat data (for testing or reset)
  Future<void> clearAllData() async {
    await _storageService.removeData(_zakatInputKey);
        await _storageService.removeData(_zakatHistoryKey);

    _logger.info('All Zakat data cleared');
  }

  /// Get Zakat educational content
  Map<String, String> getEducationalContent() {
    return ZakatInfo.getGeneralInfo();
  }

  /// Get asset type information
  Map<String, String> getAssetTypeInfo(ZakatAssetType type) {
    return ZakatInfo.getAssetTypeInfo(type);
  }

  /// Dispose of resources
  void dispose() {
    _logger.info('ZakatCalculatorService disposed');
  }
}