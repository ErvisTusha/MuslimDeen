import 'package:flutter/material.dart';
import 'package:muslim_deen/models/hadith.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/hadith_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class HadithView extends StatefulWidget {
  const HadithView({super.key});

  @override
  State<HadithView> createState() => _HadithViewState();
}

class _HadithViewState extends State<HadithView> {
  final HadithService _hadithService = locator<HadithService>();
  late Hadith _currentHadith;

  @override
  void initState() {
    super.initState();
    _currentHadith = _hadithService.getHadithOfTheDay(DateTime.now());
  }

  void _loadNewHadith() {
    setState(() {
      _currentHadith = _hadithService.getRandomHadith();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      appBar: CustomAppBar(title: 'Daily Hadith', brightness: brightness),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book,
                        size: 48,
                        color: AppColors.primary(brightness),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '"${_currentHadith.text}"',
                        style: const TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Narrated by: ${_currentHadith.narrator}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Source: ${_currentHadith.source}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Grade: ${_currentHadith.grade}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary(brightness),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadNewHadith,
              icon: const Icon(Icons.refresh),
              label: const Text('Get Another Hadith'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
