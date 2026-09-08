import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/budget_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }
  await initializeDateFormatting('id_ID', null);
  await initializeDateFormatting('en_US', null);
  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initSession()),
      ],
      child: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, child) {
          final isDark = settings.isDarkMode;

          // Show loading while checking session
          if (auth.isCheckingSession) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: Scaffold(
                backgroundColor: settings.backgroundColor,
                body: Center(
                  child: CircularProgressIndicator(color: settings.primaryColor),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Budget Manager',
            debugShowCheckedModeBanner: false,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              primaryColor: const Color(0xFF6366F1),
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF6366F1),
                secondary: Color(0xFF10B981),
                surface: Color(0xFFFFFFFF),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              primaryColor: const Color(0xFF6366F1),
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF6366F1),
                secondary: Color(0xFF10B981),
                surface: Color(0xFF1E293B),
              ),
            ),
            home: auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
