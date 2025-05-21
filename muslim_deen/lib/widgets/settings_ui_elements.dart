import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Key? sectionKey; // Renamed from key to avoid conflict with Widget.key

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.sectionKey,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Row(
        key: sectionKey,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.sectionTitle(brightness).copyWith(
                color: AppColors.primary(brightness),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class SettingsListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background(brightness),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor(brightness)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.iconInactive(brightness)),
        title: Text(title, style: AppTextStyles.prayerName(brightness)),
        subtitle: Text(subtitle, style: AppTextStyles.label(brightness)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.iconInactive(brightness),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}