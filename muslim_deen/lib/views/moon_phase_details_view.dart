import 'package:flutter/material.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/moon_phases_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class MoonPhaseDetailsView extends StatefulWidget {
  final DateTime? selectedDate;

  const MoonPhaseDetailsView({super.key, this.selectedDate});

  @override
  State<MoonPhaseDetailsView> createState() => _MoonPhaseDetailsViewState();
}

class _MoonPhaseDetailsViewState extends State<MoonPhaseDetailsView> {
  final MoonPhasesService _moonService = locator<MoonPhasesService>();

  MoonPhaseInfo? _currentPhase;
  List<MoonPhaseInfo> _upcomingPhases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoonPhaseData();
  }

  Future<void> _loadMoonPhaseData() async {
    setState(() => _isLoading = true);

    try {
      final targetDate = widget.selectedDate ?? DateTime.now();
      final currentPhase = _moonService.calculateMoonPhase(targetDate);

      // Get upcoming phases for the next 30 days
      final endDate = targetDate.add(const Duration(days: 30));
      final allPhases = _moonService.getMoonPhasesForRange(targetDate, endDate);

      // Filter to significant phases only
      final upcomingPhases = allPhases.where((phase) =>
        phase.phase == MoonPhase.newMoon ||
        phase.phase == MoonPhase.fullMoon ||
        phase.phase == MoonPhase.firstQuarter ||
        phase.phase == MoonPhase.lastQuarter
      ).take(4).toList();

      setState(() {
        _currentPhase = currentPhase;
        _upcomingPhases = upcomingPhases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Moon Phase Details',
        brightness: brightness,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
            onRefresh: _loadMoonPhaseData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentPhase != null) ...[
                    _buildCurrentPhaseCard(brightness),
                    const SizedBox(height: 24),
                  ],
                  _buildUpcomingPhasesCard(brightness),
                  const SizedBox(height: 24),
                  _buildMoonPhaseGuideCard(brightness),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCurrentPhaseCard(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _currentPhase!.displayColor.withAlpha(200),
            _currentPhase!.displayColor.withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _currentPhase!.displayColor.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentPhase!.icon,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Phase',
                      style: AppTextStyles.dateSecondary(brightness).copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPhase!.phaseName,
                      style: AppTextStyles.sectionTitle(brightness).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_currentPhase!.illumination * 100).toStringAsFixed(1)}% Illuminated',
                      style: AppTextStyles.dateSecondary(brightness).copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _currentPhase!.description,
            style: AppTextStyles.prayerName(brightness).copyWith(
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingPhasesCard(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider(brightness), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Moon Phases',
            style: AppTextStyles.sectionTitle(brightness),
          ),
          const SizedBox(height: 16),
          if (_upcomingPhases.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No upcoming significant moon phases found',
                  style: AppTextStyles.dateSecondary(brightness),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ..._upcomingPhases.map((phase) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: phase.displayColor.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      phase.icon,
                      color: phase.displayColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.phaseName,
                          style: AppTextStyles.prayerName(brightness).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${phase.date.day}/${phase.date.month}/${phase.date.year}',
                          style: AppTextStyles.dateSecondary(brightness),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(phase.illumination * 100).toStringAsFixed(0)}%',
                    style: AppTextStyles.prayerName(brightness).copyWith(
                      color: phase.displayColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildMoonPhaseGuideCard(Brightness brightness) {
    final phases = [
      (MoonPhase.newMoon, 'New Moon', 'Invisible from Earth'),
      (MoonPhase.waxingCrescent, 'Waxing Crescent', 'Thin crescent after sunset'),
      (MoonPhase.firstQuarter, 'First Quarter', 'Half illuminated'),
      (MoonPhase.waxingGibbous, 'Waxing Gibbous', 'More than half lit'),
      (MoonPhase.fullMoon, 'Full Moon', 'Fully illuminated'),
      (MoonPhase.waningGibbous, 'Waning Gibbous', 'More than half lit'),
      (MoonPhase.lastQuarter, 'Last Quarter', 'Half illuminated'),
      (MoonPhase.waningCrescent, 'Waning Crescent', 'Thin crescent before sunrise'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider(brightness), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moon Phase Guide',
            style: AppTextStyles.sectionTitle(brightness),
          ),
          const SizedBox(height: 16),
          ...phases.map((phaseData) {
            // Create a temporary MoonPhaseInfo for display
            final displayPhase = MoonPhaseInfo(
              phase: phaseData.$1,
              illumination: 0.5,
              date: DateTime.now(),
              phaseName: phaseData.$2,
              description: phaseData.$3,
              icon: _getPhaseIcon(phaseData.$1),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: displayPhase.displayColor.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      displayPhase.icon,
                      color: displayPhase.displayColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phaseData.$2,
                          style: AppTextStyles.prayerName(brightness).copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          phaseData.$3,
                          style: AppTextStyles.dateSecondary(brightness).copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getPhaseIcon(MoonPhase phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return Icons.brightness_2;
      case MoonPhase.waxingCrescent:
      case MoonPhase.waningCrescent:
        return Icons.brightness_3;
      case MoonPhase.firstQuarter:
      case MoonPhase.lastQuarter:
        return Icons.brightness_4;
      case MoonPhase.waxingGibbous:
      case MoonPhase.waningGibbous:
        return Icons.brightness_5;
      case MoonPhase.fullMoon:
        return Icons.brightness_7;
    }
  }
}