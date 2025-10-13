/// Types of assets subject to Zakat
enum ZakatAssetType {
  cash,           // Cash in hand, bank accounts
  gold,           // Gold and gold jewelry
  silver,         // Silver and silver items
  stocks,         // Stocks and shares
  business,       // Business inventory and assets
  livestock,      // Cattle, sheep, goats, camels
  agriculture,    // Agricultural produce
  other,          // Other assets
}

/// Zakat calculation result
class ZakatCalculation {
  final double totalAssets;
  final double totalLiabilities;
  final double netAssets;
  final double zakatAmount;
  final double nisabThreshold;
  final bool isZakatDue;
  final DateTime calculationDate;
  final Map<ZakatAssetType, double> assetBreakdown;
  final Map<String, double> liabilityBreakdown;

  ZakatCalculation({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netAssets,
    required this.zakatAmount,
    required this.nisabThreshold,
    required this.isZakatDue,
    required this.calculationDate,
    required this.assetBreakdown,
    required this.liabilityBreakdown,
  });

  /// Create calculation from asset and liability data
  factory ZakatCalculation.calculate({
    required Map<ZakatAssetType, double> assets,
    required Map<String, double> liabilities,
    required double nisabThreshold,
  }) {
    final totalAssets = assets.values.fold(0.0, (sum, value) => sum + value);
    final totalLiabilities = liabilities.values.fold(0.0, (sum, value) => sum + value);
    final netAssets = totalAssets - totalLiabilities;

    final isZakatDue = netAssets >= nisabThreshold;
    final zakatAmount = isZakatDue ? netAssets * 0.025 : 0.0; // 2.5% of net assets

    return ZakatCalculation(
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      netAssets: netAssets,
      zakatAmount: zakatAmount,
      nisabThreshold: nisabThreshold,
      isZakatDue: isZakatDue,
      calculationDate: DateTime.now(),
      assetBreakdown: Map.from(assets),
      liabilityBreakdown: Map.from(liabilities),
    );
  }

  /// Get summary as formatted text
  String getSummary() {
    final currency = 'USD'; // Could be made configurable
    return '''
Zakat Calculation Summary
═══════════════════════════
Total Assets: ${totalAssets.toStringAsFixed(2)} $currency
Total Liabilities: ${totalLiabilities.toStringAsFixed(2)} $currency
Net Assets: ${netAssets.toStringAsFixed(2)} $currency
Nisab Threshold: ${nisabThreshold.toStringAsFixed(2)} $currency

Zakat Due: ${isZakatDue ? 'Yes' : 'No'}
Zakat Amount: ${zakatAmount.toStringAsFixed(2)} $currency

Calculated on: ${calculationDate.toString().split(' ')[0]}
''';
  }

  @override
  String toString() {
    return 'ZakatCalculation(netAssets: $netAssets, zakatAmount: $zakatAmount, isDue: $isZakatDue)';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'totalAssets': totalAssets,
      'totalLiabilities': totalLiabilities,
      'netAssets': netAssets,
      'zakatAmount': zakatAmount,
      'nisabThreshold': nisabThreshold,
      'isZakatDue': isZakatDue,
      'calculationDate': calculationDate.toIso8601String(),
      'assetBreakdown': assetBreakdown.map((key, value) => MapEntry(key.index.toString(), value)),
      'liabilityBreakdown': liabilityBreakdown,
    };
  }
}

/// Zakat calculator input data
class ZakatInput {
  final Map<ZakatAssetType, double> assets;
  final Map<String, double> liabilities;
  final String currency;
  final double nisabValue;
  final DateTime lastCalculation;

  ZakatInput({
    required this.assets,
    required this.liabilities,
    this.currency = 'USD',
    required this.nisabValue,
    DateTime? lastCalculation,
  }) : lastCalculation = lastCalculation ?? DateTime.now();

  /// Create from JSON
  factory ZakatInput.fromJson(Map<String, dynamic> json) {
    return ZakatInput(
      assets: (json['assets'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(ZakatAssetType.values[int.parse(key)], value as double),
      ),
      liabilities: (json['liabilities'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as double),
      ),
      currency: json['currency'] as String? ?? 'USD',
      nisabValue: json['nisabValue'] as double,
      lastCalculation: DateTime.parse(json['lastCalculation'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'assets': assets.map((key, value) => MapEntry(key.index.toString(), value)),
      'liabilities': liabilities,
      'currency': currency,
      'nisabValue': nisabValue,
      'lastCalculation': lastCalculation.toIso8601String(),
    };
  }

  /// Create empty input
  factory ZakatInput.empty() {
    return ZakatInput(
      assets: {},
      liabilities: {},
      nisabValue: 0.0,
    );
  }

  /// Check if input has any data
  bool get hasData => assets.values.any((value) => value > 0) || liabilities.values.any((value) => value > 0);

  @override
  String toString() {
    return 'ZakatInput(assets: ${assets.length}, liabilities: ${liabilities.length}, currency: $currency)';
  }
}

/// Zakat educational information
class ZakatInfo {
  static const double zakatRate = 0.025; // 2.5%
  static const int lunarMonths = 12; // Lunar year for Zakat calculation

  /// Get information about Zakat for different asset types
  static Map<String, String> getAssetTypeInfo(ZakatAssetType type) {
    switch (type) {
      case ZakatAssetType.cash:
        return {
          'title': 'Cash and Savings',
          'description': 'Cash in hand, bank accounts, money lent to others',
          'rate': '2.5% of total amount held for one lunar year',
          'nisab': 'Equivalent to 85g of gold or 595g of silver',
        };
      case ZakatAssetType.gold:
        return {
          'title': 'Gold and Jewelry',
          'description': 'Gold jewelry, coins, and bullion',
          'rate': '2.5% of value above Nisab threshold',
          'nisab': '85g of gold',
        };
      case ZakatAssetType.silver:
        return {
          'title': 'Silver',
          'description': 'Silver jewelry, coins, and items',
          'rate': '2.5% of value above Nisab threshold',
          'nisab': '595g of silver',
        };
      case ZakatAssetType.stocks:
        return {
          'title': 'Stocks and Investments',
          'description': 'Shares, bonds, and investment portfolios',
          'rate': '2.5% of current market value',
          'nisab': 'Based on cash equivalent value',
        };
      case ZakatAssetType.business:
        return {
          'title': 'Business Assets',
          'description': 'Inventory, equipment, and business investments',
          'rate': '2.5% of net business assets',
          'nisab': 'Standard Nisab threshold',
        };
      case ZakatAssetType.livestock:
        return {
          'title': 'Livestock',
          'description': 'Cattle, sheep, goats, camels for breeding',
          'rate': 'Varies by type and number',
          'nisab': '5 cattle, 40 sheep/goats, 5 camels',
        };
      case ZakatAssetType.agriculture:
        return {
          'title': 'Agricultural Produce',
          'description': 'Crops, fruits, and agricultural products',
          'rate': '5% or 10% depending on irrigation method',
          'nisab': '5 wasaq (approximately 653kg)',
        };
      case ZakatAssetType.other:
        return {
          'title': 'Other Assets',
          'description': 'Other Zakatable assets not covered above',
          'rate': '2.5% of value',
          'nisab': 'Standard Nisab threshold',
        };
    }
  }

  /// Get general Zakat information
  static Map<String, String> getGeneralInfo() {
    return {
      'definition': 'Zakat is one of the Five Pillars of Islam. It is obligatory almsgiving, intended to purify wealth and souls.',
      'purpose': 'Zakat purifies wealth, promotes social welfare, reduces inequality, and fosters community solidarity.',
      'timing': 'Zakat becomes obligatory when wealth reaches the Nisab threshold and has been held for one lunar year.',
      'distribution': 'Zakat should be distributed to the eight categories mentioned in the Quran: the poor, orphans, widows, etc.',
      'importance': 'Zakat is both a spiritual act and a social responsibility that strengthens the Muslim community.',
    };
  }

  /// Calculate Nisab threshold based on current gold/silver prices
  static double calculateNisab({
    required double goldPricePerGram,
    required double silverPricePerGram,
    bool useGold = true,
  }) {
    if (useGold) {
      // Nisab is 85g of gold
      return 85.0 * goldPricePerGram;
    } else {
      // Alternative: 595g of silver
      return 595.0 * silverPricePerGram;
    }
  }

  /// Check if one lunar year has passed since last Zakat payment
  static bool isZakatYearComplete(DateTime lastPayment) {
    final now = DateTime.now();
    final lunarYear = Duration(days: (lunarMonths * 29.5).round()); // Approximate lunar year
    return now.difference(lastPayment) >= lunarYear;
  }
}