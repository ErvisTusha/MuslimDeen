import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';

class CitySearchResultsList extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;
  final Brightness brightness;
  final Color contentSurfaceColor;
  final Color borderColor;
  final Color listTileSelectedColor;
  final Color textColor;
  final Color hintColor;
  final Color iconColor;
  final void Function(Map<String, dynamic>) onSelectLocation;

  const CitySearchResultsList({
    super.key,
    required this.searchResults,
    required this.brightness,
    required this.contentSurfaceColor,
    required this.borderColor,
    required this.listTileSelectedColor,
    required this.textColor,
    required this.hintColor,
    required this.iconColor,
    required this.onSelectLocation,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = brightness == Brightness.dark;

    if (searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: contentSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withAlpha(isDarkMode ? 100 : 150),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: searchResults.length,
          separatorBuilder: (context, index) => Divider(
            color: borderColor.withAlpha(isDarkMode ? 70 : 100),
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final result = searchResults[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelectLocation(result),
                splashColor: listTileSelectedColor,
                highlightColor: listTileSelectedColor.withAlpha(80),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result['name'] as String,
                              style: AppTextStyles.prayerName(brightness).copyWith(
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${result['latitude'].toStringAsFixed(4)}, ${result['longitude'].toStringAsFixed(4)}',
                              style: AppTextStyles.label(brightness).copyWith(
                                color: hintColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: iconColor,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}