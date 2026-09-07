import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';

class SettingsToggles extends StatelessWidget {
  final bool compact;

  const SettingsToggles({Key? key, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: settings.surfaceColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: settings.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: settings.isDarkMode ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language Switch Pill (ID / EN)
          GestureDetector(
            onTap: () => settings.toggleLanguage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: settings.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: settings.primaryColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Text(
                    settings.language == 'ID' ? '🇮🇩' : '🇬🇧',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    settings.language,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: settings.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: compact ? 8 : 12),

          // Theme Switch Pill (Light / Dark)
          GestureDetector(
            onTap: () => settings.toggleTheme(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: settings.isDarkMode
                    ? const Color(0xFF1E1B4B)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: settings.isDarkMode
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFF59E0B),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    settings.isDarkMode ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                    size: 14,
                    color: settings.isDarkMode
                        ? const Color(0xFFA5B4FC)
                        : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    settings.isDarkMode ? 'Dark' : 'Light',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: settings.isDarkMode
                          ? const Color(0xFFA5B4FC)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
