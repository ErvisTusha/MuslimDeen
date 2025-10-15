import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/zakat.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/zakat_calculator_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

/// Zakat Calculator View - allows users to calculate their Zakat obligation
class ZakatCalculatorView extends ConsumerStatefulWidget {
  const ZakatCalculatorView({super.key});

  @override
  ConsumerState<ZakatCalculatorView> createState() =>
      _ZakatCalculatorViewState();
}

class _ZakatCalculatorViewState extends ConsumerState<ZakatCalculatorView> {
  ZakatCalculatorService? _zakatService;

  final Map<ZakatAssetType, TextEditingController> _assetControllers = {};
  final Map<String, TextEditingController> _liabilityControllers = {};
  final Map<String, TextEditingController> _customAssetControllers = {};

  ZakatCalculation? _calculation;
  bool _isLoading = true;
  bool _showResults = false;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _initializeService();
    _initializeControllers();
    _loadSavedData();
  }

  Future<void> _initializeService() async {
    try {
      _zakatService = await locator.getAsync<ZakatCalculatorService>();
    } catch (e) {
      // Handle service initialization error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize Zakat service')),
        );
      }
    }
  }

  void _initializeControllers() {
    // Initialize asset controllers
    for (final type in ZakatAssetType.values) {
      _assetControllers[type] = TextEditingController(text: '0.00');
    }

    // Initialize liability controllers
    _liabilityControllers['Debts'] = TextEditingController(text: '0.00');
    _liabilityControllers['Loans'] = TextEditingController(text: '0.00');
    _liabilityControllers['Other Liabilities'] = TextEditingController(
      text: '0.00',
    );
  }

  Future<void> _loadSavedData() async {
    if (_zakatService == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final savedInput = await _zakatService!.loadZakatInput();
      if (savedInput != null) {
        _loadInputData(savedInput);
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadInputData(ZakatInput input) {
    _currency = input.currency;

    // Load asset values
    for (final entry in input.assets.entries) {
      _assetControllers[entry.key]?.text = entry.value.toStringAsFixed(2);
    }

    // Load liability values
    for (final entry in input.liabilities.entries) {
      _liabilityControllers[entry.key]?.text = entry.value.toStringAsFixed(2);
    }
  }

  Future<void> _calculateZakat() async {
    if (_zakatService == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Zakat service not available')),
        );
      }
      return;
    }

    final assets = <ZakatAssetType, double>{};
    final liabilities = <String, double>{};

    // Parse asset values
    for (final entry in _assetControllers.entries) {
      final value = double.tryParse(entry.value.text) ?? 0.0;
      if (value > 0) {
        assets[entry.key] = value;
      }
    }

    // Parse liability values
    for (final entry in _liabilityControllers.entries) {
      final value = double.tryParse(entry.value.text) ?? 0.0;
      if (value > 0) {
        liabilities[entry.key] = value;
      }
    }

    final nisabValue = _zakatService!.getCurrentNisab();
    final input = ZakatInput(
      assets: assets,
      liabilities: liabilities,
      currency: _currency,
      nisabValue: nisabValue,
    );

    try {
      final calculation = await _zakatService!.calculateZakat(input);
      setState(() {
        _calculation = calculation;
        _showResults = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to calculate Zakat')),
        );
      }
    }
  }

  void _resetCalculator() {
    setState(() {
      _showResults = false;
      _calculation = null;
      _initializeControllers();
    });
  }

  @override
  void dispose() {
    for (final controller in _assetControllers.values) {
      controller.dispose();
    }
    for (final controller in _liabilityControllers.values) {
      controller.dispose();
    }
    for (final controller in _customAssetControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (_isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Zakat Calculator', brightness: brightness),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Zakat Calculator', brightness: brightness),
      body:
          _showResults
              ? _buildResultsView(brightness)
              : _buildInputView(brightness),
    );
  }

  Widget _buildInputView(Brightness brightness) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header with educational info
        _buildHeader(brightness),

        const SizedBox(height: 24),

        // Currency selector
        _buildCurrencySelector(brightness),

        const SizedBox(height: 24),

        // Assets section
        _buildAssetsSection(brightness),

        const SizedBox(height: 24),

        // Liabilities section
        _buildLiabilitiesSection(brightness),

        const SizedBox(height: 24),

        // Calculate button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _calculateZakat,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Calculate Zakat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Educational footer
        _buildEducationalFooter(brightness),
      ],
    );
  }

  Widget _buildResultsView(Brightness brightness) {
    if (_calculation == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Results header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                _calculation!.isZakatDue
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _calculation!.isZakatDue ? Colors.green : Colors.orange,
            ),
          ),
          child: Column(
            children: [
              Icon(
                _calculation!.isZakatDue ? Icons.check_circle : Icons.info,
                color: _calculation!.isZakatDue ? Colors.green : Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                _calculation!.isZakatDue ? 'Zakat Due' : 'No Zakat Due',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      _calculation!.isZakatDue ? Colors.green : Colors.orange,
                ),
              ),
              if (_calculation!.isZakatDue) ...[
                const SizedBox(height: 8),
                Text(
                  '${_calculation!.zakatAmount.toStringAsFixed(2)} $_currency',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Detailed breakdown
        _buildDetailedBreakdown(brightness),

        const SizedBox(height: 24),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _resetCalculator,
                child: const Text('Recalculate'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Could implement sharing or saving results
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Results saved')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Results'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zakat Calculator',
            style: AppTextStyles.sectionTitle(brightness),
          ),
          const SizedBox(height: 8),
          Text(
            'Calculate your Zakat obligation based on your assets and liabilities. Zakat is obligatory on Muslims who meet the Nisab threshold.',
            style: AppTextStyles.label(brightness),
          ),
          const SizedBox(height: 8),
          Text(
            'Current Nisab: ${_zakatService?.getCurrentNisab().toStringAsFixed(2) ?? 'Loading...'} $_currency',
            style: AppTextStyles.prayerTime(brightness).copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.accentGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '(Estimate based on approximate market prices. Please verify with a local source.)',
            style: AppTextStyles.label(brightness).copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector(Brightness brightness) {
    return Row(
      children: [
        Text('Currency:', style: AppTextStyles.prayerTime(brightness)),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: _currency,
          items:
              ['USD', 'EUR', 'GBP', 'SAR', 'AED', 'PKR', 'BDT', 'MYR', 'IDR']
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _currency = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAssetsSection(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assets', style: AppTextStyles.sectionTitle(brightness)),
          const SizedBox(height: 16),
          ...ZakatAssetType.values.map(
            (type) => _buildAssetInput(type, brightness),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetInput(ZakatAssetType type, Brightness brightness) {
    final controller = _assetControllers[type]!;
    final info = ZakatInfo.getAssetTypeInfo(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _getAssetTypeDisplayName(type),
                  style: AppTextStyles.prayerTime(brightness),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 16),
                onPressed: () => _showAssetInfoDialog(type, info),
              ),
            ],
          ),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: '0.00',
              suffixText: _currency,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilitiesSection(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liabilities (Debts & Obligations)',
            style: AppTextStyles.sectionTitle(brightness),
          ),
          const SizedBox(height: 16),
          ..._liabilityControllers.entries.map(
            (entry) => _buildLiabilityInput(entry.key, entry.value, brightness),
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilityInput(
    String name,
    TextEditingController controller,
    Brightness brightness,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTextStyles.prayerTime(brightness)),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              hintText: '0.00',
              suffixText: _currency,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdown(Brightness brightness) {
    if (_calculation == null || _zakatService == null)
      return const SizedBox.shrink();

    final breakdown = _zakatService!.getDetailedBreakdown(_calculation!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detailed Breakdown',
            style: AppTextStyles.sectionTitle(brightness),
          ),
          const SizedBox(height: 16),

          // Summary
          _buildBreakdownRow(
            'Total Assets',
            breakdown['summary']['totalAssets'],
            brightness,
          ),
          _buildBreakdownRow(
            'Total Liabilities',
            breakdown['summary']['totalLiabilities'],
            brightness,
          ),
          const Divider(),
          _buildBreakdownRow(
            'Net Assets',
            breakdown['summary']['netAssets'],
            brightness,
            isBold: true,
          ),
          _buildBreakdownRow(
            'Nisab Threshold',
            breakdown['summary']['nisabThreshold'],
            brightness,
          ),
          const Divider(),
          _buildBreakdownRow(
            'Zakat Amount',
            breakdown['summary']['zakatAmount'],
            brightness,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    dynamic value,
    Brightness brightness, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                isBold
                    ? AppTextStyles.prayerTime(
                      brightness,
                    ).copyWith(fontWeight: FontWeight.bold)
                    : AppTextStyles.prayerTime(brightness),
          ),
          Text(
            '${(value as num).toStringAsFixed(2)} $_currency',
            style:
                isBold
                    ? AppTextStyles.prayerTime(
                      brightness,
                    ).copyWith(fontWeight: FontWeight.bold)
                    : AppTextStyles.prayerTime(brightness),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalFooter(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Zakat', style: AppTextStyles.sectionTitle(brightness)),
          const SizedBox(height: 8),
          Text(
            'Zakat is one of the Five Pillars of Islam. It purifies wealth and helps establish social welfare. The rate is 2.5% of eligible assets held for one lunar year.',
            style: AppTextStyles.label(brightness),
          ),
        ],
      ),
    );
  }

  void _showAssetInfoDialog(ZakatAssetType type, Map<String, String> info) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(info['title'] ?? ''),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${info['description']}'),
                const SizedBox(height: 8),
                Text('Rate: ${info['rate']}'),
                if (info['nisab'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Nisab: ${info['nisab']}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  String _getAssetTypeDisplayName(ZakatAssetType type) {
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
}
