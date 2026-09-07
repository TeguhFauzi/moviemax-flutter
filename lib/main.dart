import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/env_config.dart';
import 'providers/movie_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/call_provider.dart';
import 'providers/chat_provider.dart';
import 'widgets/push_notification_banner.dart';
import 'views/login_screen.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.init();
  runApp(const MovieMaxApp());
}

class MovieMaxApp extends StatelessWidget {
  const MovieMaxApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MovieProvider()..fetchHomeData()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initSession()),
        ChangeNotifierProvider(create: (_) => CallProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: Consumer2<SettingsProvider, AuthProvider>(
        builder: (context, settings, auth, child) {
          final isDark = settings.isDarkMode;

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

          if (auth.isLoggedIn) {
            Provider.of<ChatProvider>(context, listen: false).init(auth.userName);
            Provider.of<CallProvider>(context, listen: false).bind(auth.userName);
          }

          return MaterialApp(
            title: 'MovieMAX Mobile',
            debugShowCheckedModeBanner: false,
            navigatorKey: appNavigatorKey,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              primaryColor: const Color(0xFF4F46E5),
              useMaterial3: true,
              textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4F46E5),
                secondary: Color(0xFF059669),
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
            builder: (context, child) {
              return GlobalNotificationOverlay(
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}

