import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/gravity_background.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessageKey;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin(SettingsProvider settings) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _errorMessageKey = null);

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessageKey = 'login_empty_error');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));

    final success = await auth.loginWithCredentials(username, password);
    if (success) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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
      backgroundColor: Colors.transparent,
      body: GravityBackgroundWidget(
        settings: settings,
        child: Stack(
          children: [
            // Language & theme toggles
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => settings.toggleLanguage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: settings.surfaceColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: settings.cardBorderColor),
                        ),
                        child: Text(
                          settings.language,
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: settings.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => settings.toggleTheme(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: settings.surfaceColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: settings.cardBorderColor),
                        ),
                        child: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 18,
                          color: settings.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Login form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // Card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: settings.surfaceColor.withValues(alpha: isDark ? 0.65 : 0.75),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: settings.cardBorderColor.withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo matching modern finance app icon
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [settings.primaryColor, const Color(0xFF818CF8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: settings.primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, size: 44, color: Colors.white),
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
                          const SizedBox(height: 8),
                          Text(
                            settings.tr('login_welcome'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 14, color: settings.textSecondaryColor),
                          ),
                          const SizedBox(height: 28),

                          // Username
                          Text(
                            settings.tr('username_label'),
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: settings.textSecondaryColor),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameController,
                            style: GoogleFonts.inter(color: settings.textPrimaryColor),
                            decoration: _inputDecoration(settings, settings.tr('username_hint'), Icons.person_rounded),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          Text(
                            settings.tr('password_label'),
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: settings.textSecondaryColor),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.inter(color: settings.textPrimaryColor),
                            decoration: _inputDecoration(settings, settings.tr('password_hint'), Icons.lock_rounded).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: settings.textMutedColor,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            onSubmitted: (_) => _handleLogin(settings),
                          ),
                          const SizedBox(height: 8),

                          // Error
                          if (_errorMessageKey != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: settings.dangerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: settings.dangerColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: settings.dangerColor, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      settings.tr(_errorMessageKey!),
                                      style: GoogleFonts.inter(color: settings.dangerColor, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Login button
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _handleLogin(settings),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: settings.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Text(settings.tr('login_button')),
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
    ),
    );
  }

  InputDecoration _inputDecoration(SettingsProvider settings, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: settings.textMutedColor),
      prefixIcon: Icon(icon, color: settings.textMutedColor, size: 20),
      filled: true,
      fillColor: settings.inputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: settings.cardBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: settings.cardBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: settings.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
