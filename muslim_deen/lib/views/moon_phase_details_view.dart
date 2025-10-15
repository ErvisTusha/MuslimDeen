import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  late DateTime _selectedDate;
  MoonPhaseInfo? _currentPhase;
  List<MoonPhaseInfo> _upcomingPhases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final baseDate = widget.selectedDate ?? DateTime.now();
    _selectedDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    _loadMoonPhaseData();
  }

  Future<void> _loadMoonPhaseData() async {
    setState(() => _isLoading = true);

    try {
      await _moonService.init();
      final currentPhase = _moonService.calculateMoonPhase(_selectedDate);
      final upcoming = _calculateUpcomingSignificantPhases(_selectedDate);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPhase = currentPhase;
        _upcomingPhases = upcoming;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to load moon phase data'),
          backgroundColor: AppColors.error(Theme.of(context).brightness),
        ),
      );
    }
  }

  List<MoonPhaseInfo> _calculateUpcomingSignificantPhases(DateTime start) {
    final rangeStart = DateTime(
      start.year,
      start.month,
      start.day,
    ).add(const Duration(days: 1));
    final rangeEnd = rangeStart.add(const Duration(days: 60));
    final phases = _moonService.getMoonPhasesForRange(rangeStart, rangeEnd);

    final List<MoonPhaseInfo> upcoming = [];
    for (final phase in phases) {
      if (!_isSignificantPhase(phase.phase)) {
        continue;
      }

      final alreadyCaptured = upcoming.any(
        (entry) =>
            entry.phase == phase.phase && _isSameDay(entry.date, phase.date),
      );

      if (!alreadyCaptured) {
        upcoming.add(phase);
      }

      if (upcoming.length >= 6) {
        break;
      }
    }

    return upcoming;
  }

  bool _isSignificantPhase(MoonPhase phase) {
    return phase == MoonPhase.newMoon ||
        phase == MoonPhase.fullMoon ||
        phase == MoonPhase.firstQuarter ||
        phase == MoonPhase.lastQuarter;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(_selectedDate.year - 1),
      lastDate: DateTime(_selectedDate.year + 1),
    );

    if (picked == null) {
      return;
    }

    final normalized = DateTime(picked.year, picked.month, picked.day);
    if (_isSameDay(normalized, _selectedDate)) {
      return;
    }

    setState(() => _selectedDate = normalized);
    _loadMoonPhaseData();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: CustomAppBar(
        title: 'Moon Phase Details',
        brightness: brightness,
        actions: [
          IconButton(
            onPressed: _selectDate,
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.accentGreen),
              )
              : RefreshIndicator(
                onRefresh: _loadMoonPhaseData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentPhaseCard(brightness),
                      const SizedBox(height: 24),
                      _buildIslamicSignificanceSection(brightness),
                      const SizedBox(height: 24),
                      _buildUpcomingPhasesSection(brightness),
                      const SizedBox(height: 24),
                      _buildMoonPhaseGuide(brightness),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildCurrentPhaseCard(Brightness brightness) {
    if (_currentPhase == null) {
      return Card(
        color: AppColors.surface(brightness),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No moon phase data available',
            style: AppTextStyles.bodyMedium(brightness),
          ),
        ),
      );
    }

    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isSignificant = _isSignificantPhase(_currentPhase!.phase);
    final accent = AppColors.accentGreen;

    return Card(
      elevation: 4,
      color: AppColors.surface(brightness),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_currentPhase!.icon, size: 48, color: accent),
                const SizedBox(width: 16),
                Text(
                  _currentPhase!.phaseName,
                  style: AppTextStyles.headlineSmall(
                    brightness,
                  ).copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isToday
                  ? 'Current moon phase'
                  : 'Moon phase on ${DateFormat('MMMM d, yyyy').format(_selectedDate)}',
              style: AppTextStyles.titleMedium(brightness),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Illumination: ${(_currentPhase!.illumination * 100).toStringAsFixed(1)}%',
              style: AppTextStyles.bodyLarge(brightness),
            ),
            const SizedBox(height: 12),
            Text(
              _currentPhase!.description,
              style: AppTextStyles.bodyMedium(brightness),
              textAlign: TextAlign.center,
            ),
            if (isSignificant) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withAlpha((0.12 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accent.withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: Text(
                  'Significant phase',
                  style: AppTextStyles.labelMedium(
                    brightness,
                  ).copyWith(color: accent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIslamicSignificanceSection(Brightness brightness) {
    final info = _getIslamicSignificance(_currentPhase?.phase);

    return Card(
      color: AppColors.surface(brightness),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mosque, color: AppColors.accentGreen, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Islamic significance',
                  style: AppTextStyles.titleLarge(brightness),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(info.description, style: AppTextStyles.bodyMedium(brightness)),
            if (info.practices.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recommended practices',
                style: AppTextStyles.titleSmall(brightness),
              ),
              const SizedBox(height: 8),
              ...info.practices.map(
                (practice) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.stars, size: 16, color: AppColors.accentGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          practice,
                          style: AppTextStyles.bodySmall(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingPhasesSection(Brightness brightness) {
    return Card(
      color: AppColors.surface(brightness),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming significant phases',
              style: AppTextStyles.titleLarge(brightness),
            ),
            const SizedBox(height: 12),
            if (_upcomingPhases.isEmpty)
              Text(
                'No significant phases in the next 60 days.',
                style: AppTextStyles.bodySmall(brightness),
              )
            else
              ..._upcomingPhases.map(
                (phase) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: phase.displayColor.withAlpha(
                            (0.15 * 255).round(),
                          ),
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
                              style: AppTextStyles.titleSmall(brightness),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMMM d, yyyy').format(phase.date),
                              style: AppTextStyles.bodySmall(brightness),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(phase.illumination * 100).toStringAsFixed(1)}%',
                        style: AppTextStyles.bodySmall(brightness),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoonPhaseGuide(Brightness brightness) {
    return Card(
      color: AppColors.surface(brightness),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moon phase guide',
              style: AppTextStyles.titleLarge(brightness),
            ),
            const SizedBox(height: 16),
            ..._phaseGuideEntries().map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(entry.icon, size: 24, color: AppColors.accentGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: AppTextStyles.titleSmall(brightness),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.description,
                            style: AppTextStyles.bodySmall(brightness),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IslamicSignificance _getIslamicSignificance(MoonPhase? phase) {
    switch (phase) {
      case MoonPhase.newMoon:
        return const IslamicSignificance(
          description:
              'The new moon marks the beginning of an Islamic month and is traditionally observed to confirm Ramadan, Shawwal, and other significant months.',
          practices: [
            'Observe the sky for the Hilal',
            'Reaffirm intentions for the new month',
            'Reflect on upcoming spiritual goals',
          ],
        );
      case MoonPhase.fullMoon:
        return const IslamicSignificance(
          description:
              'The full moon occurs around the 14th and 15th of the Islamic month, a time associated with increased blessings and optional fasting days.',
          practices: [
            'Consider the Ayam al-Bid fasting (13th, 14th, 15th)',
            'Increase night prayers and reflection',
            'Share meals or charity with the community',
          ],
        );
      case MoonPhase.firstQuarter:
        return const IslamicSignificance(
          description:
              'The first quarter aligns with the earlier part of the month, encouraging balanced routines and steady acts of worship.',
          practices: [
            'Maintain consistent daily prayers',
            'Plan charitable giving for the month',
          ],
        );
      case MoonPhase.lastQuarter:
        return const IslamicSignificance(
          description:
              'The last quarter often overlaps with the final third of the month, signalling preparation for closing acts of worship, especially during Ramadan.',
          practices: [
            'Intensify supplications and remembrance',
            'Seek Laylat al-Qadr in Ramadan',
            'Consider I\'tikaf if possible',
          ],
        );
      default:
        return const IslamicSignificance(
          description:
              'Each lunar phase is a reminder of the Islamic lunar calendar and offers an opportunity to align worship with the natural cycles created by Allah.',
          practices: [
            'Track the Hijri calendar for key events',
            'Schedule family learning around lunar phases',
            'Use moonlight as a moment for reflection and gratitude',
          ],
        );
    }
  }

  List<_PhaseGuideEntry> _phaseGuideEntries() {
    return const [
      _PhaseGuideEntry(
        name: 'New Moon',
        icon: Icons.brightness_2,
        description:
            'Moon positioned between Earth and Sun; generally not visible. Marks the start of the Islamic month.',
      ),
      _PhaseGuideEntry(
        name: 'Waxing Crescent',
        icon: Icons.brightness_3,
        description:
            'Sliver of moon visible after sunset. Traditionally observed to confirm the new month.',
      ),
      _PhaseGuideEntry(
        name: 'First Quarter',
        icon: Icons.brightness_4,
        description:
            'Half of the moon illuminated. Visible in the afternoon and early evening.',
      ),
      _PhaseGuideEntry(
        name: 'Waxing Gibbous',
        icon: Icons.brightness_5,
        description:
            'More than half illuminated and increasing toward the full moon.',
      ),
      _PhaseGuideEntry(
        name: 'Full Moon',
        icon: Icons.brightness_7,
        description: 'Moon fully illuminated throughout the night.',
      ),
      _PhaseGuideEntry(
        name: 'Waning Gibbous',
        icon: Icons.brightness_5,
        description:
            'More than half illuminated but decreasing after the full moon.',
      ),
      _PhaseGuideEntry(
        name: 'Last Quarter',
        icon: Icons.brightness_4,
        description:
            'Half of the moon illuminated, visible after midnight and in the morning.',
      ),
      _PhaseGuideEntry(
        name: 'Waning Crescent',
        icon: Icons.brightness_3,
        description:
            'Thin crescent visible before sunrise leading into the next new moon.',
      ),
    ];
  }
}

class IslamicSignificance {
  final String description;
  final List<String> practices;

  const IslamicSignificance({
    required this.description,
    required this.practices,
  });
}

class _PhaseGuideEntry {
  final String name;
  final IconData icon;
  final String description;

  const _PhaseGuideEntry({
    required this.name,
    required this.icon,
    required this.description,
  });
}
