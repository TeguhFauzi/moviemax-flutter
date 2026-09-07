import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  String _language = 'ID'; // 'ID' or 'EN'

  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void toggleLanguage() {
    _language = _language == 'ID' ? 'EN' : 'ID';
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (lang == 'ID' || lang == 'EN') {
      _language = lang;
      notifyListeners();
    }
  }

  // Dynamic Theme Colors
  Color get backgroundColor => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get surfaceColor => _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  Color get cardBorderColor => _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color get textPrimaryColor => _isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get textSecondaryColor => _isDarkMode ? Colors.white60 : const Color(0xFF64748B);
  Color get textMutedColor => _isDarkMode ? Colors.white38 : const Color(0xFF94A3B8);
  Color get inputFillColor => _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  Color get primaryColor => const Color(0xFF6366F1);
  Color get accentColor => const Color(0xFF10B981);
  Color get warningColor => const Color(0xFFF59E0B);
  Color get dangerColor => const Color(0xFFEF4444);

  // Localization Dictionary
  static final Map<String, Map<String, String>> _localizedStrings = {
    'ID': {
      'app_title': 'MovieMAX',
      'login_welcome': 'Masuk ke Akun Anda',
      'login_subtitle': 'Akses koleksi film terbaik & lokasi real-time',
      'username_label': 'Username',
      'username_hint': 'Masukkan username Anda',
      'password_label': 'Kata Sandi',
      'password_hint': 'Masukkan kata sandi',
      'login_button': 'MASUK SEKARANG',
      'login_empty_error': 'Silakan isi username dan kata sandi',
      'login_invalid_error': 'Username atau kata sandi tidak sesuai. Silakan periksa kembali.',
      'home_tab': 'Beranda',
      'chat_tab': 'Obrolan',
      'map_tab': 'Peta Lokasi',
      'watchlist_tab': 'Katalog & Watchlist',
      'profile_tab': 'Profil',
      'trending_title': 'Trending Minggu Ini',
      'popular_title': 'Populer Saat Ini',
      'top_rated_title': 'Rating Tertinggi',
      'all_genres': 'Semua',
      'search_hint': 'Cari film, genre, atau serial...',
      'no_results': 'Hasil pencarian tidak ditemukan.',
      'synopsis_title': 'Sinopsis',
      'no_synopsis': 'Tidak ada deskripsi sinopsis.',
      'genre_title': 'Genre',
      'cast_title': 'Pemeran Utama (Cast)',
      'add_watchlist': '+ Watchlist',
      'saved_watchlist': 'Tersimpan',
      'watch_party_btn': 'Nonton Bersama',
      'watch_party_title': 'Room Nonton Bersama',
      'watch_party_live': 'LIVE SINKRON',
      'watch_party_partner': 'Teman Nonton',
      'watch_party_chat_hint': 'Ketik pesan untuk teman nonton...',
      'watch_party_send': 'Kirim',
      'watch_party_room_code': 'Kode Room',
      'watchlist_removed_toast': 'Dihapus dari Watchlist Neon DB',
      'watchlist_saved_toast': 'Disimpan ke Watchlist Neon DB',
      'watchlist_empty_title': 'Belum Ada Film Favorit',
      'watchlist_empty_sub': 'Simpan film favorit Anda ke database Neon PostgreSQL',
      'profile_title': 'Profil Saya',
      'profile_settings': 'Pengaturan Aplikasi',
      'profile_dark_mode': 'Mode Gelap (Dark Mode)',
      'profile_language': 'Bahasa Aplikasi',
      'profile_services': 'Status Layanan Integrasi (.env)',
      'profile_logout_btn': 'Keluar dari Akun (Logout)',
      'logout_dialog_title': 'Konfirmasi Keluar',
      'logout_dialog_body': 'Apakah Anda yakin ingin keluar dari akun MovieMAX?',
      'cancel': 'Batal',
      'logout': 'Keluar',
      'map_screen_title': 'Real Device GPS & Network',
      'map_my_location': 'Lokasi Saya',
      'focus_amrhdla': 'Fokus amrhdla',
      'focus_tfauzyy': 'Fokus tfauzyy',
      'distance_between': 'Jarak amrhdla ↔ tfauzyy:',
      'provider_info': 'Provider & Jaringan',
      'film_not_found': 'Film tidak ditemukan',
      'upload_avatar_success': 'Foto profil berhasil diperbarui!',
      'upload_avatar_fail': 'Gagal memperbarui foto profil',
    },
    'EN': {
      'app_title': 'MovieMAX',
      'login_welcome': 'Sign In to Your Account',
      'login_subtitle': 'Access premium movie collection & real-time location',
      'username_label': 'Username',
      'username_hint': 'Enter your username',
      'password_label': 'Password',
      'password_hint': 'Enter your password',
      'login_button': 'SIGN IN NOW',
      'login_empty_error': 'Please enter both username and password',
      'login_invalid_error': 'Invalid username or password. Please check again.',
      'home_tab': 'Home',
      'chat_tab': 'Chats',
      'map_tab': 'Location Map',
      'watchlist_tab': 'Catalog & Watchlist',
      'profile_tab': 'Profile',
      'trending_title': 'Trending This Week',
      'popular_title': 'Popular Right Now',
      'top_rated_title': 'Top Rated Movies',
      'all_genres': 'All',
      'search_hint': 'Search movies, genres, or series...',
      'no_results': 'No search results found.',
      'synopsis_title': 'Synopsis',
      'no_synopsis': 'No synopsis description available.',
      'genre_title': 'Genres',
      'cast_title': 'Main Cast',
      'add_watchlist': '+ Watchlist',
      'saved_watchlist': 'Saved',
      'watch_party_btn': 'Watch Together',
      'watch_party_title': 'Watch Party Room',
      'watch_party_live': 'LIVE SYNCED',
      'watch_party_partner': 'Watch Partner',
      'watch_party_chat_hint': 'Type a message for watch party...',
      'watch_party_send': 'Send',
      'watch_party_room_code': 'Room Code',
      'watchlist_removed_toast': 'Removed from Neon DB Watchlist',
      'watchlist_saved_toast': 'Saved to Neon DB Watchlist',
      'watchlist_empty_title': 'No Favorite Movies Yet',
      'watchlist_empty_sub': 'Save your favorite movies to your Neon PostgreSQL database',
      'profile_title': 'My Profile',
      'profile_settings': 'Application Settings',
      'profile_dark_mode': 'Dark Mode Theme',
      'profile_language': 'App Language',
      'profile_services': 'Integration Service Status (.env)',
      'profile_logout_btn': 'Log Out of Account',
      'logout_dialog_title': 'Confirm Logout',
      'logout_dialog_body': 'Are you sure you want to log out of MovieMAX?',
      'cancel': 'Cancel',
      'logout': 'Log Out',
      'map_screen_title': 'Real Device GPS & Network',
      'map_my_location': 'My Location',
      'focus_amrhdla': 'Focus amrhdla',
      'focus_tfauzyy': 'Focus tfauzyy',
      'distance_between': 'Distance amrhdla ↔ tfauzyy:',
      'provider_info': 'Provider & Network',
      'film_not_found': 'Movie not found',
      'upload_avatar_success': 'Profile avatar updated successfully!',
      'upload_avatar_fail': 'Failed to update profile avatar',
    },
  };

  String tr(String key) {
    final langMap = _localizedStrings[_language] ?? _localizedStrings['ID']!;
    return langMap[key] ?? key;
  }
}
