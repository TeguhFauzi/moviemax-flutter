import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie_model.dart';
import '../config/env_config.dart';
import '../services/tmdb_service.dart';
import '../providers/movie_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/settings_toggles.dart';
import 'watch_party_screen.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailScreen({Key? key, required this.movieId}) : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final TmdbService _tmdbService = TmdbService();
  MovieDetail? _movieDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await _tmdbService.getMovieDetails(widget.movieId);
    if (mounted) {
      setState(() {
        _movieDetail = detail;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = Provider.of<MovieProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: settings.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: settings.primaryColor),
        ),
      );
    }

    if (_movieDetail == null) {
      return Scaffold(
        backgroundColor: settings.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Text(
            settings.tr('film_not_found'),
            style: TextStyle(color: settings.textPrimaryColor),
          ),
        ),
      );
    }

    final detail = _movieDetail!;
    final isSaved = movieProvider.isWatchlisted(detail.id);

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Backdrop Image
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: settings.backgroundColor,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: SettingsToggles(compact: true),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  detail.backdropPath.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: '${EnvConfig.tmdbBackdropBaseUrl}${detail.backdropPath}',
                          fit: BoxFit.cover,
                        )
                      : Container(color: Colors.grey[900]),
                  // Dynamic Gradient Overlay based on theme
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          settings.backgroundColor.withValues(alpha: 0.6),
                          settings.backgroundColor,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Rating Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          detail.title,
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: settings.textPrimaryColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: settings.warningColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: settings.warningColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, color: settings.warningColor, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              detail.voteAverage.toStringAsFixed(1),
                              style: GoogleFonts.inter(
                                color: settings.warningColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Meta Specs (Runtime, Release Date)
                  Row(
                    children: [
                      if (detail.releaseDate.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: settings.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: settings.cardBorderColor),
                          ),
                          child: Text(
                            detail.releaseDate.split('-').first,
                            style: TextStyle(color: settings.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (detail.runtime > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: settings.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: settings.cardBorderColor),
                          ),
                          child: Text(
                            '${detail.runtime} min',
                            style: TextStyle(color: settings.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons (Nonton Bersama & Watchlist)
                  Row(
                    children: [
                      // Watch Together / Nonton Bersama Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WatchPartyScreen(
                                    movieId: detail.id,
                                    movieTitle: detail.title,
                                    backdropPath: detail.backdropPath,
                                    posterPath: detail.posterPath,
                                    trailerKey: detail.trailerKey,
                                  ),
                                ),
                              );
                            },
                            icon: const Text('🍿', style: TextStyle(fontSize: 16)),
                            label: Text(
                              settings.tr('watch_party_btn'),
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Watchlist Toggle Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            movieProvider.toggleWatchlist(
                              Movie(
                                id: detail.id,
                                title: detail.title,
                                overview: detail.overview,
                                posterPath: detail.posterPath,
                                backdropPath: detail.backdropPath,
                                voteAverage: detail.voteAverage,
                                voteCount: 0,
                                releaseDate: detail.releaseDate,
                                genreIds: detail.genres.map((g) => g.id).toList(),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isSaved
                                      ? settings.tr('watchlist_removed_toast')
                                      : settings.tr('watchlist_saved_toast'),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(
                            isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            isSaved ? settings.tr('saved_watchlist') : settings.tr('add_watchlist'),
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSaved ? settings.accentColor : settings.surfaceColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isSaved ? settings.accentColor : settings.cardBorderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Overview Header
                  Text(
                    settings.tr('synopsis_title'),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: settings.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    detail.overview.isNotEmpty ? detail.overview : settings.tr('no_synopsis'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: settings.textSecondaryColor,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Genres List
                  if (detail.genres.isNotEmpty) ...[
                    Text(
                      settings.tr('genre_title'),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: settings.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: detail.genres
                          .map(
                            (g) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: settings.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: settings.cardBorderColor),
                              ),
                              child: Text(
                                g.name,
                                style: TextStyle(color: settings.textPrimaryColor, fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Cast Members
                  if (detail.cast.isNotEmpty) ...[
                    Text(
                      settings.tr('cast_title'),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: settings.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: detail.cast.length,
                        itemBuilder: (context, index) {
                          final c = detail.cast[index];
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: settings.surfaceColor,
                                  backgroundImage: c.profilePath.isNotEmpty
                                      ? NetworkImage('${EnvConfig.tmdbImageBaseUrl}${c.profilePath}')
                                      : null,
                                  child: c.profilePath.isEmpty
                                      ? Icon(Icons.person, color: settings.textMutedColor)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(color: settings.textPrimaryColor, fontSize: 11),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
