import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              settings.tr('settings'),
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
            ),
            const SizedBox(height: 24),

            // User Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [settings.primaryColor, const Color(0xFF818CF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.userName.isNotEmpty ? auth.userName : 'elnins',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.userEmail.isNotEmpty ? auth.userEmail : 'elnins@budget.app',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings List
            _buildSettingTile(
              icon: Icons.dark_mode_rounded,
              title: settings.tr('dark_mode'),
              subtitle: settings.isDarkMode ? 'ON' : 'OFF',
              settings: settings,
              trailing: Switch(
                value: settings.isDarkMode,
                onChanged: (_) => settings.toggleTheme(),
                activeThumbColor: settings.primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            _buildSettingTile(
              icon: Icons.language_rounded,
              title: settings.tr('language'),
              subtitle: settings.language == 'ID' ? 'Bahasa Indonesia' : 'English',
              settings: settings,
              trailing: GestureDetector(
                onTap: () => settings.toggleLanguage(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: settings.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    settings.language,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: settings.primaryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // About
            Text(
              'About',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: settings.textSecondaryColor),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: settings.surfaceColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: settings.cardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Manager',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aplikasi manajemen keuangan pribadi. Data tersimpan lokal di perangkat menggunakan SQLite.',
                    style: GoogleFonts.inter(fontSize: 13, color: settings.textSecondaryColor, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.storage_rounded, size: 16, color: settings.textMutedColor),
                      const SizedBox(width: 8),
                      Text('SQLite Local Storage', style: GoogleFonts.inter(fontSize: 12, color: settings.textMutedColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone_android_rounded, size: 16, color: settings.textMutedColor),
                      const SizedBox(width: 8),
                      Text('Flutter Framework', style: GoogleFonts.inter(fontSize: 12, color: settings.textMutedColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: settings.dangerColor.withValues(alpha: 0.15),
                  foregroundColor: settings.dangerColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: settings.dangerColor.withValues(alpha: 0.3)),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  settings.tr('logout'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: settings.surfaceColor,
                      title: Text(settings.tr('logout'), style: GoogleFonts.outfit(color: settings.textPrimaryColor)),
                      content: Text(settings.tr('logout_confirm'), style: GoogleFonts.inter(color: settings.textSecondaryColor)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(settings.tr('cancel')),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await auth.logout();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          child: Text(settings.tr('logout'), style: TextStyle(color: settings.dangerColor)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required SettingsProvider settings,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: settings.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: settings.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: settings.primaryColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: settings.textPrimaryColor)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: settings.textSecondaryColor)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
