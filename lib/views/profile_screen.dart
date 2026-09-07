import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_toggles.dart';
import '../config/env_config.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final success = await authProvider.uploadAvatar(image.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? settings.tr('upload_avatar_success')
                  : settings.tr('upload_avatar_fail'),
            ),
          ),
        );
      }
    }
  }

  void _handleLogout(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: settings.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: settings.cardBorderColor),
        ),
        title: Text(
          settings.tr('logout_dialog_title'),
          style: GoogleFonts.outfit(color: settings.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          settings.tr('logout_dialog_body'),
          style: GoogleFonts.inter(color: settings.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(settings.tr('cancel'), style: TextStyle(color: settings.textMutedColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: settings.dangerColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(settings.tr('logout'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.backgroundColor,
        elevation: 0,
        title: Text(
          settings.tr('profile_title'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: settings.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: settings.dangerColor),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Profile Avatar with Cloudinary Badge
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [settings.primaryColor, settings.accentColor],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: settings.surfaceColor,
                      backgroundImage: authProvider.avatarUrl != null
                          ? NetworkImage(authProvider.avatarUrl!)
                          : null,
                      child: authProvider.avatarUrl == null
                          ? Text(
                              authProvider.userName.substring(0, 1).toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: settings.primaryColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: () => _pickAndUploadImage(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: settings.accentColor,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: authProvider.isUploadingAvatar
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              authProvider.userName,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: settings.textPrimaryColor,
              ),
            ),
            Text(
              authProvider.userEmail,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: settings.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 28),

            // Application Settings Card (Language Switch & Theme Toggle)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: settings.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: settings.cardBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.tr('profile_settings'),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: settings.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Language Setting Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: settings.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.language_rounded, color: settings.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                settings.tr('profile_language'),
                                style: GoogleFonts.inter(
                                  color: settings.textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                settings.language == 'ID' ? 'Bahasa Indonesia 🇮🇩' : 'English 🇬🇧',
                                style: GoogleFonts.inter(
                                  color: settings.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SettingsToggles(compact: true),
                    ],
                  ),

                  const Divider(height: 24),

                  // Theme Setting Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: settings.warningColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              settings.isDarkMode ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                              color: settings.warningColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                settings.tr('profile_dark_mode'),
                                style: GoogleFonts.inter(
                                  color: settings.textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                settings.isDarkMode ? 'Dark Theme' : 'Light Theme',
                                style: GoogleFonts.inter(
                                  color: settings.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: settings.isDarkMode,
                        activeThumbColor: settings.primaryColor,
                        onChanged: (val) => settings.setDarkMode(val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Environment Credentials Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: settings.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: settings.cardBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.tr('profile_services'),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: settings.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildServiceTile(
                    'TMDB Movie Engine',
                    EnvConfig.tmdbApiKey.isNotEmpty ? 'Connected' : 'Missing',
                    Icons.movie_filter_rounded,
                    settings.primaryColor,
                    settings,
                  ),
                  const SizedBox(height: 12),
                  _buildServiceTile(
                    'Cloudinary Cloud Storage',
                    EnvConfig.cloudinaryCloudName.isNotEmpty ? 'Connected (${EnvConfig.cloudinaryCloudName})' : 'Missing',
                    Icons.cloud_upload_rounded,
                    settings.accentColor,
                    settings,
                  ),
                  const SizedBox(height: 12),
                  _buildServiceTile(
                    'Neon PostgreSQL Database',
                    EnvConfig.databaseUrl.isNotEmpty ? 'Connected (AWS East)' : 'Missing',
                    Icons.storage_rounded,
                    settings.warningColor,
                    settings,
                  ),
                  const SizedBox(height: 12),
                  _buildServiceTile(
                    'Firebase Authentication',
                    EnvConfig.firebaseProjectId.isNotEmpty ? 'Active (${EnvConfig.firebaseProjectId})' : 'Missing',
                    Icons.local_fire_department_rounded,
                    settings.dangerColor,
                    settings,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Red Logout Button
            ElevatedButton.icon(
              onPressed: () => _handleLogout(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              label: Text(
                settings.tr('profile_logout_btn'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: settings.dangerColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTile(String title, String status, IconData icon, Color color, SettingsProvider settings) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: settings.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                status,
                style: GoogleFonts.inter(
                  color: settings.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded, color: settings.accentColor, size: 18),
      ],
    );
  }
}
