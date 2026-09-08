import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  String _language = 'ID';

  static const String _themeKey = 'settings_dark_mode';
  static const String _langKey = 'settings_language';

  bool get isDarkMode => _isDarkMode;
  String get language => _language;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true;
    _language = prefs.getString(_langKey) ?? 'ID';
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }

  void toggleLanguage() async {
    _language = _language == 'ID' ? 'EN' : 'ID';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, _language);
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
  Color get incomeColor => const Color(0xFF10B981);
  Color get expenseColor => const Color(0xFFEF4444);

  // Localization
  static final Map<String, Map<String, String>> _strings = {
    'ID': {
      'app_title': 'Budget Manager',
      'home_tab': 'Beranda',
      'transactions_tab': 'Transaksi',
      'stats_tab': 'Statistik',
      'settings_tab': 'Pengaturan',
      'total_balance': 'Saldo Total',
      'income': 'Pemasukan',
      'expense': 'Pengeluaran',
      'add_transaction': 'Tambah Transaksi',
      'edit_transaction': 'Edit Transaksi',
      'title': 'Judul',
      'amount': 'Jumlah',
      'category': 'Kategori',
      'date': 'Tanggal',
      'note': 'Catatan',
      'save': 'Simpan',
      'cancel': 'Batal',
      'delete': 'Hapus',
      'delete_confirm': 'Yakin hapus transaksi ini?',
      'no_transactions': 'Belum ada transaksi',
      'recent_transactions': 'Transaksi Terbaru',
      'all_transactions': 'Semua Transaksi',
      'this_month': 'Bulan Ini',
      'expense_by_category': 'Pengeluaran per Kategori',
      'income_by_category': 'Pemasukan per Kategori',
      'daily_chart': 'Grafik Harian',
      'monthly_summary': 'Ringkasan Bulanan',
      'dark_mode': 'Mode Gelap',
      'language': 'Bahasa',
      'settings': 'Pengaturan',
      'title_required': 'Judul wajib diisi',
      'amount_required': 'Jumlah wajib diisi',
      'amount_invalid': 'Jumlah tidak valid',
      'select_category': 'Pilih Kategori',
      'overview': 'Ringkasan',
      'login_welcome': 'Masuk ke Akun Anda',
      'username_label': 'Username',
      'username_hint': 'Masukkan username',
      'password_label': 'Kata Sandi',
      'password_hint': 'Masukkan kata sandi',
      'login_button': 'MASUK',
      'login_empty_error': 'Username dan kata sandi wajib diisi',
      'login_invalid_error': 'Username atau kata sandi salah',
      'logout': 'Keluar',
      'logout_confirm': 'Yakin ingin keluar dari akun?',
      'logged_in_as': 'Masuk sebagai',
      'smart_planner_title': 'Smart Budget Planner',
      'planning_target': 'Perencanaan & Target Tabungan',
      'current_balance_label': 'Total Uang / Saldo Saat Ini',
      'savings_target_label': 'Target Uang yang Ingin Disimpan (Saving)',
      'period_duration_label': 'Jangka Waktu Periode Anggaran',
      'daily_limit_title': 'Batas Jajan Maksimal Per Hari',
      'safe_to_spend': 'Bisa Dipakai (Safe)',
      'disimpan_savings': 'Disimpan (Savings)',
      'daily_recommendation': 'Rekomendasi Alokasi Anggaran Harian',
      'save_target_button': 'Simpan Target / Goal Ini',
      'goal_saved_success': 'Target / Goal Smart Budget berhasil disimpan!',
      'days_unit': 'Hari',
      'per_day': 'hari',
      'smart_suggestion_title': 'Smart Suggestion Hari Ini',
      'remaining_days_prefix': 'Sisa',
      'remaining_days_suffix': 'hari lagi (s/d tgl 25)',
      'status_safe': 'Aman',
      'status_overbudget': 'Membengkak!',
      'target_goal_savings': 'Target Goal Savings:',
      'daily_spend_limit': 'Limit Jajan Hari Ini',
      'spent_today': 'Terpakai Hari Ini',
      'food_label': 'Makan & Minum',
      'cigarette_label': 'Rokok',
      'goal_expense_suggestion_title': 'Saran Pengeluaran Agar Target Savings Tercapai:',
      'goal_daily_limit_label': 'Batas Maks Pengeluaran Harian',
      'critical_food_alert': '🚨 Peringatan Kritis Engine: Sisa anggaran harian terlalu kecil untuk jatah makan! Target savings berisiko tidak realistis.',
      'overbudget_food_warning': '⚠️ Limit Hari Ini Habis! Pengeluaran berlebih hari ini berisiko memotong jatah makan esok hari.',
    },
    'EN': {
      'app_title': 'Budget Manager',
      'home_tab': 'Home',
      'transactions_tab': 'Transactions',
      'stats_tab': 'Statistics',
      'settings_tab': 'Settings',
      'total_balance': 'Total Balance',
      'income': 'Income',
      'expense': 'Expense',
      'add_transaction': 'Add Transaction',
      'edit_transaction': 'Edit Transaction',
      'title': 'Title',
      'amount': 'Amount',
      'category': 'Category',
      'date': 'Date',
      'note': 'Note',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'delete_confirm': 'Are you sure you want to delete this transaction?',
      'no_transactions': 'No transactions yet',
      'recent_transactions': 'Recent Transactions',
      'all_transactions': 'All Transactions',
      'this_month': 'This Month',
      'expense_by_category': 'Expense by Category',
      'income_by_category': 'Income by Category',
      'daily_chart': 'Daily Chart',
      'monthly_summary': 'Monthly Summary',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'settings': 'Settings',
      'title_required': 'Title is required',
      'amount_required': 'Amount is required',
      'amount_invalid': 'Invalid amount',
      'select_category': 'Select Category',
      'overview': 'Overview',
      'login_welcome': 'Sign In to Your Account',
      'username_label': 'Username',
      'username_hint': 'Enter your username',
      'password_label': 'Password',
      'password_hint': 'Enter your password',
      'login_button': 'SIGN IN',
      'login_empty_error': 'Username and password are required',
      'login_invalid_error': 'Invalid username or password',
      'logout': 'Log Out',
      'logout_confirm': 'Are you sure you want to log out?',
      'logged_in_as': 'Logged in as',
      'smart_planner_title': 'Smart Budget Planner',
      'planning_target': 'Planning & Savings Target',
      'current_balance_label': 'Total Money / Current Balance',
      'savings_target_label': 'Target Savings Amount',
      'period_duration_label': 'Budget Period Duration',
      'daily_limit_title': 'Maximum Daily Spending Limit',
      'safe_to_spend': 'Safe to Spend',
      'disimpan_savings': 'Target Savings',
      'daily_recommendation': 'Daily Budget Allocation Recommendation',
      'save_target_button': 'Save Target / Goal',
      'goal_saved_success': 'Smart Budget Target / Goal saved successfully!',
      'days_unit': 'Days',
      'per_day': 'day',
      'smart_suggestion_title': "Today's Smart Suggestion",
      'remaining_days_prefix': '',
      'remaining_days_suffix': 'days remaining (until 25th)',
      'status_safe': 'Safe',
      'status_overbudget': 'Overbudget!',
      'target_goal_savings': 'Savings Target Goal:',
      'daily_spend_limit': 'Daily Spending Limit',
      'spent_today': 'Spent Today',
      'food_label': 'Food & Drink',
      'cigarette_label': 'Cigarette',
      'goal_expense_suggestion_title': 'Suggested Daily Limit to Reach Target Goal:',
      'goal_daily_limit_label': 'Max Daily Expense Limit',
      'critical_food_alert': '🚨 Critical Engine Alert: Remaining daily budget is too low for food meals! Savings target may be unrealistic.',
      'overbudget_food_warning': '⚠️ Daily Limit Depleted! Overspending today risks cutting into tomorrow\'s meal budget.',
    },
  };

  String tr(String key) {
    final langMap = _strings[_language] ?? _strings['ID']!;
    return langMap[key] ?? key;
  }
}
