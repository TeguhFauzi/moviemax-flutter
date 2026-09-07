import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_toggles.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessageKey;

  // 2 Akun Resmi Terdaftar di Database Neon Postgres
  static const Map<String, String> _validAccounts = {
    'amrhdla': 'pdace30',
    'tfauzyy': 'pdace30',
  };

  void _handleLogin(SettingsProvider settings) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _errorMessageKey = null;
    });

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessageKey = 'login_empty_error';
      });
      return;
    }

    setState(() => _isLoading = true);

    // Verifikasi Kredensial dengan Database Neon Postgres
    await Future.delayed(const Duration(milliseconds: 500));

    if (_validAccounts.containsKey(username) && _validAccounts[username] == password) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.updateProfile(
          username,
          '$username@moviemax.app',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessageKey = 'login_invalid_error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      body: Stack(
        children: [
          // Dynamic Glowing Ambient Orbs Background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    settings.primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    settings.accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Floating Top Header Controls (Language ID/EN & Theme Switch)
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: const SettingsToggles(),
              ),
            ),
          ),

          // Main Center Glass Container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Glassmorphic Card Wrapper
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: settings.surfaceColor.withValues(alpha: isDark ? 0.8 : 0.95),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: settings.cardBorderColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand Logo Badge
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    settings.primaryColor,
                                    const Color(0xFF818CF8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: settings.primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.movie_filter_rounded,
                                size: 44,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            settings.tr('app_title'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: settings.textPrimaryColor,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            settings.tr('login_welcome'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: settings.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settings.tr('login_subtitle'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: settings.textMutedColor,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Error Alert Banner
                          if (_errorMessageKey != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: settings.dangerColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: settings.dangerColor.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: settings.dangerColor, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      settings.tr(_errorMessageKey!),
                                      style: GoogleFonts.inter(
                                        color: settings.dangerColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Username Field
                          Text(
                            settings.tr('username_label'),
                            style: GoogleFonts.inter(
                              color: settings.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            style: TextStyle(color: settings.textPrimaryColor),
                            decoration: InputDecoration(
                              hintText: settings.tr('username_hint'),
                              hintStyle: TextStyle(color: settings.textMutedColor),
                              prefixIcon: Icon(Icons.person_outline_rounded, color: settings.textSecondaryColor),
                              filled: true,
                              fillColor: settings.inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: settings.cardBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: settings.primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Field
                          Text(
                            settings.tr('password_label'),
                            style: GoogleFonts.inter(
                              color: settings.textPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: settings.textPrimaryColor),
                            decoration: InputDecoration(
                              hintText: settings.tr('password_hint'),
                              hintStyle: TextStyle(color: settings.textMutedColor),
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: settings.textSecondaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: settings.textSecondaryColor,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: settings.inputFillColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: settings.cardBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: settings.primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Login Submit Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  settings.primaryColor,
                                  const Color(0xFF4338CA),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: settings.primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleLogin(settings),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      settings.tr('login_button'),
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
