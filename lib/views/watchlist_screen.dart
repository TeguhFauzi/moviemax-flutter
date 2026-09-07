import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/movie_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_toggles.dart';
import '../models/movie_model.dart';
import '../config/env_config.dart';
import 'movie_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({Key? key}) : super(key: key);

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  int _selectedTab = 0; // 0: Katalog Master TMDB, 1: Watchlist Saya (Neon DB)

  @override
  Widget build(BuildContext context) {
    final movieProvider = Provider.of<MovieProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final watchlist = movieProvider.watchlist;

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.backgroundColor,
        elevation: 0,
        title: Text(
          settings.tr('watchlist_tab'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: settings.textPrimaryColor,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SettingsToggles(compact: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented Tab Bar (Katalog Master Film vs Watchlist Saya)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: settings.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: settings.cardBorderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? settings.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🎬 Katalog Master Film',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 0 ? Colors.white : settings.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? settings.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '🔖 Watchlist Saya (${watchlist.length})',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 1 ? Colors.white : settings.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab View Content
          Expanded(
            child: _selectedTab == 0
                ? _buildMasterCatalogView(context, movieProvider, settings)
                : _buildMyWatchlistView(context, movieProvider, settings),
          ),
        ],
      ),
    );
  }

  // Katalog Master Film (TMDB API Key in .env)
  Widget _buildMasterCatalogView(BuildContext context, MovieProvider provider, SettingsProvider settings) {
    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator(color: settings.primaryColor));
    }

    final allMovies = provider.filteredPopularMovies.isNotEmpty
        ? provider.filteredPopularMovies
        : provider.popularMovies;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Search Field
          TextField(
            onChanged: (val) => provider.search(val),
            style: TextStyle(color: settings.textPrimaryColor),
            decoration: InputDecoration(
              hintText: settings.tr('search_hint'),
              hintStyle: TextStyle(color: settings.textMutedColor),
              prefixIcon: Icon(Icons.search_rounded, color: settings.textSecondaryColor),
              filled: true,
              fillColor: settings.inputFillColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          const SizedBox(height: 16),

          // Genres Filter
          if (provider.genres.isNotEmpty) ...[
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.genres.length + 1,
                itemBuilder: (context, index) {
                  final isAll = index == 0;
                  final genreId = isAll ? 0 : provider.genres[index - 1].id;
                  final genreName = isAll ? settings.tr('all_genres') : provider.genres[index - 1].name;
                  final isSelected = provider.selectedGenreId == genreId;

                  return GestureDetector(
                    onTap: () => provider.selectGenre(genreId),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? settings.primaryColor : settings.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? settings.primaryColor : settings.cardBorderColor,
                        ),
                      ),
                      child: Text(
                        genreName,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : settings.textSecondaryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Grid View of Master Movies
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: allMovies.length,
            itemBuilder: (context, index) {
              final movie = allMovies[index];
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
                              ? CachedNetworkImage(
                                  imageUrl: '${EnvConfig.tmdbImageBaseUrl}${movie.posterPath}',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Container(color: Colors.grey[800]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: settings.textPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded, color: settings.warningColor, size: 14),
                                    const SizedBox(width: 2),
                                    Text(
                                      movie.voteAverage.toStringAsFixed(1),
                                      style: GoogleFonts.inter(color: settings.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: settings.primaryColor, size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Watchlist Saya (Neon DB)
  Widget _buildMyWatchlistView(BuildContext context, MovieProvider provider, SettingsProvider settings) {
    final watchlist = provider.watchlist;

    if (watchlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline_rounded,
              size: 80,
              color: settings.textMutedColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              settings.tr('watchlist_empty_title'),
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: settings.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              settings.tr('watchlist_empty_sub'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: settings.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: watchlist.length,
      itemBuilder: (context, index) {
        final item = watchlist[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: settings.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: settings.cardBorderColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.posterPath.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: '${EnvConfig.tmdbImageBaseUrl}${item.posterPath}',
                      width: 60,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie_rounded, color: Colors.white54),
                    ),
            ),
            title: Text(
              item.title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: settings.textPrimaryColor,
                fontSize: 16,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(Icons.star_rounded, color: settings.warningColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  item.voteAverage.toStringAsFixed(1),
                  style: GoogleFonts.inter(color: settings.textSecondaryColor, fontSize: 13),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: settings.dangerColor),
              onPressed: () {
                final movie = provider.popularMovies.firstWhere(
                  (m) => m.id == item.movieId,
                  orElse: () => provider.trendingMovies.firstWhere(
                    (m) => m.id == item.movieId,
                    orElse: () => provider.watchlist.firstWhere(
                      (w) => w.movieId == item.movieId,
                      orElse: () => null as dynamic,
                    ) as dynamic,
                  ),
                );
                provider.toggleWatchlist(movie);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(settings.tr('watchlist_removed_toast')),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(movieId: item.movieId),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
