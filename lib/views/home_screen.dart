import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/settings_provider.dart';
import '../widgets/gravity_background.dart';
import 'dashboard_screen.dart';
import 'transaction_list_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    TransactionListScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GravityBackgroundWidget(
        settings: settings,
        tabIndex: _currentIndex,
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: settings.surfaceColor,
          border: Border(top: BorderSide(color: settings.cardBorderColor, width: 1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Global Language & Darkmode Bar in Navigation Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Global Controls',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: settings.textMutedColor),
                    ),
                    Row(
                      children: [
                        // Language Toggle Switch
                        GestureDetector(
                          onTap: () => settings.toggleLanguage(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: settings.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: settings.primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.language_rounded, size: 14, color: settings.primaryColor),
                                const SizedBox(width: 4),
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
                        const SizedBox(width: 8),
                        // Dark mode Toggle Button
                        GestureDetector(
                          onTap: () => settings.toggleTheme(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: settings.inputFillColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: settings.cardBorderColor),
                            ),
                            child: Icon(
                              settings.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              size: 16,
                              color: settings.isDarkMode ? Colors.amber : settings.textPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 0.5, color: settings.cardBorderColor),
              BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                backgroundColor: settings.surfaceColor,
                selectedItemColor: settings.primaryColor,
                unselectedItemColor: settings.textMutedColor,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard_rounded),
                    label: settings.tr('home_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: settings.tr('transactions_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.pie_chart_rounded),
                    label: settings.tr('stats_tab'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.settings_rounded),
                    label: settings.tr('settings_tab'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
