import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/movie_provider.dart';
import '../providers/settings_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/settings_toggles.dart';
import 'movie_detail_screen.dart';
import 'watchlist_screen.dart';
import 'profile_screen.dart';
import 'map_tracking_screen.dart';
import 'watch_party_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Timer? _partnerWatchCheckTimer;
  int? _activePartnerMovieId;

  @override
  void initState() {
    super.initState();
    _startPartnerWatchSyncListener();
  }

  void _startPartnerWatchSyncListener() {
    _partnerWatchCheckTimer?.cancel();
    _partnerWatchCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.userName;
      final partnerUser = currentUser == 'amrhdla' ? 'tfauzyy' : 'amrhdla';
      final coupleThread = FirebaseService.directThreadId(currentUser, partnerUser);

      final state = await FirebaseService().getWatchState(coupleThread);
      if (!mounted || state == null) return;

      final partnerId = state['userId'];
      final movieId = state['movieId'];
      final movieTitle = state['movieTitle'];
      final backdropPath = state['backdropPath'] ?? '';
      final posterPath = state['posterPath'] ?? '';
      final trailerKey = state['trailerKey'] ?? '';

      if (partnerId == partnerUser && movieId != null && _activePartnerMovieId != movieId) {
        _activePartnerMovieId = movieId as int;
        _showPartnerWatchBanner(
          partnerUser: partnerUser,
          movieId: movieId,
          movieTitle: (movieTitle ?? 'Film').toString(),
          backdropPath: backdropPath.toString(),
          posterPath: posterPath.toString(),
          trailerKey: trailerKey.toString(),
        );
      }
    });
  }

  void _showPartnerWatchBanner({
    required String partnerUser,
    required int movieId,
    required String movieTitle,
    required String backdropPath,
    required String posterPath,
    required String trailerKey,
  }) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        backgroundColor: settings.surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: settings.primaryColor),
        ),
        content: Row(
          children: [
            const Text('🍿', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$partnerUser sedang menonton film!',
                    style: GoogleFonts.outfit(color: settings.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    movieTitle,
                    style: GoogleFonts.inter(color: settings.textSecondaryColor, fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: settings.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WatchPartyScreen(
                      movieId: movieId,
                      movieTitle: movieTitle,
                      backdropPath: backdropPath,
                      posterPath: posterPath,
                      trailerKey: trailerKey,
                    ),
                  ),
                );
              },
              child: Text(
                'Gabung',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _partnerWatchCheckTimer?.cancel();
    super.dispose();
  }

  final List<Widget> _pages = [
    const _HomeDashboardView(),
    const ChatScreen(),
    const WatchlistScreen(),
    const MapTrackingScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: settings.surfaceColor,
          border: Border(top: BorderSide(color: settings.cardBorderColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: settings.surfaceColor,
          selectedItemColor: settings.primaryColor,
          unselectedItemColor: settings.textMutedColor,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: settings.tr('home_tab'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_rounded),
              label: settings.tr('chat_tab'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.movie_rounded),
              label: settings.tr('watchlist_tab'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_rounded),
              label: settings.tr('map_tab'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_rounded),
              label: settings.tr('profile_tab'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboardView extends StatelessWidget {
  const _HomeDashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final movieProvider = Provider.of<MovieProvider>(context);
    final currentUser = authProvider.userName;
    final partnerUser = currentUser == 'amrhdla' ? 'tfauzyy' : 'amrhdla';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [settings.primaryColor, const Color(0xFF818CF8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: settings.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.tr('app_title'),
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: settings.textPrimaryColor,
                          ),
                        ),
                        Text(
                          'Halo, $currentUser 👋',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: settings.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SettingsToggles(compact: true),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Actions Hub Banner
            Text(
              'Akses Cepat & Fitur Utama',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: settings.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                // Obrolan & Call WhatsApp
                _buildQuickActionCard(
                  title: 'Obrolan & Calls',
                  subtitle: 'Chat & Telepon $partnerUser',
                  icon: Icons.chat_rounded,
                  color: const Color(0xFF00A884),
                  settings: settings,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatScreen()),
                    );
                  },
                ),

                // Quick Nonton Bersama
                _buildQuickActionCard(
                  title: 'Nonton Bersama',
                  subtitle: 'Stream Film Live',
                  icon: Icons.movie_filter_rounded,
                  color: const Color(0xFF8B5CF6),
                  settings: settings,
                  onTap: () {
                    final firstMovie = movieProvider.trendingMovies.isNotEmpty
                        ? movieProvider.trendingMovies.first
                        : null;
                    if (firstMovie != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WatchPartyScreen(
                            movieId: firstMovie.id,
                            movieTitle: firstMovie.title,
                            backdropPath: firstMovie.backdropPath,
                            posterPath: firstMovie.posterPath,
                          ),
                        ),
                      );
                    }
                  },
                ),

                // Quick Map Tracking
                _buildQuickActionCard(
                  title: 'Tracking GPS',
                  subtitle: 'Peta Real-Time',
                  icon: Icons.map_rounded,
                  color: settings.accentColor,
                  settings: settings,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapTrackingScreen()),
                    );
                  },
                ),

                // Katalog Master Film
                _buildQuickActionCard(
                  title: 'Katalog Film',
                  subtitle: 'TMDB Master API',
                  icon: Icons.local_movies_rounded,
                  color: settings.primaryColor,
                  settings: settings,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WatchlistScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Highlights Film Terbaru (TMDB API)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Highlight Film TMDB',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: settings.textPrimaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WatchlistScreen()),
                    );
                  },
                  child: Text('Katalog Master →', style: TextStyle(color: settings.primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (movieProvider.trendingMovies.isNotEmpty)
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: movieProvider.trendingMovies.take(8).length,
                  itemBuilder: (context, index) {
                    final movie = movieProvider.trendingMovies[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(movieId: movie.id),
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: settings.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: settings.cardBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: movie.posterPath.isNotEmpty
                                    ? Image.network(
                                        'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Container(color: Colors.grey[800]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                movie.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(color: settings.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            if (movieProvider.koreanDramas.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Drama Korea Popular 🇰🇷',
                    style: GoogleFonts.outfit(color: settings.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: movieProvider.koreanDramas.length,
                  itemBuilder: (context, index) {
                    final movie = movieProvider.koreanDramas[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(movieId: movie.id),
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: settings.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: settings.cardBorderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                child: movie.posterPath.isNotEmpty
                                    ? Image.network(
                                        'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Container(color: Colors.grey[800]),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                movie.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(color: settings.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required SettingsProvider settings,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: settings.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: settings.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: settings.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: settings.textSecondaryColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
