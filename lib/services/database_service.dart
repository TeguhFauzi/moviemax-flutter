import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'budget_manager.db';
  static const int _dbVersion = 2;

  static const String _spTxnKey = 'persistent_web_transactions';
  static const String _spCatKey = 'persistent_web_categories';
  static const String _spGoalKey = 'persistent_web_active_goal';

  // In-memory + SharedPreferences persistence fallback for Web
  static List<TransactionModel>? _memoryTransactions;
  static List<CategoryModel>? _memoryCategories;

  static Future<void> _loadWebStorage() async {
    if (_memoryTransactions != null && _memoryCategories != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Transactions
      final txnString = prefs.getString(_spTxnKey);
      if (txnString != null && txnString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(txnString);
        _memoryTransactions = decoded.map((item) => TransactionModel.fromMap(Map<String, dynamic>.from(item))).toList();
      } else {
        _memoryTransactions = [];
      }

      // Load Categories
      final catString = prefs.getString(_spCatKey);
      if (catString != null && catString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(catString);
        _memoryCategories = decoded.map((item) => CategoryModel.fromMap(Map<String, dynamic>.from(item))).toList();
      } else {
        _memoryCategories = List.from(CategoryModel.defaults);
      }
    } catch (e) {
      debugPrint('Failed to load web SharedPreferences persistence: $e');
      _memoryTransactions ??= [];
      _memoryCategories ??= List.from(CategoryModel.defaults);
    }
  }

  static Future<void> _saveWebStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_memoryTransactions != null) {
        final txnListMap = _memoryTransactions!.map((t) => t.toMap()).toList();
        await prefs.setString(_spTxnKey, jsonEncode(txnListMap));
      }
      if (_memoryCategories != null) {
        final catListMap = _memoryCategories!.map((c) => c.toMap()).toList();
        await prefs.setString(_spCatKey, jsonEncode(catListMap));
      }
    } catch (e) {
      debugPrint('Failed to save web SharedPreferences persistence: $e');
    }
  }

  static Future<Database?> get database async {
    if (kIsWeb) {
      await _loadWebStorage();
      return null;
    }
    try {
      _database ??= await _initDb();
      return _database;
    } catch (e) {
      debugPrint('Database init failed, using in-memory/shared_preferences mode: $e');
      await _loadWebStorage();
      return null;
    }
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            categoryId TEXT NOT NULL,
            note TEXT,
            date TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            iconCode INTEGER NOT NULL,
            colorValue INTEGER NOT NULL,
            isIncome INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE goals (
            id TEXT PRIMARY KEY,
            balance REAL NOT NULL,
            targetSavings REAL NOT NULL,
            startDate TEXT NOT NULL,
            endDate TEXT NOT NULL,
            dailySpendLimit REAL NOT NULL
          )
        ''');

        for (final cat in CategoryModel.defaults) {
          await db.insert('categories', cat.toMap());
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS goals (
              id TEXT PRIMARY KEY,
              balance REAL NOT NULL,
              targetSavings REAL NOT NULL,
              startDate TEXT NOT NULL,
              endDate TEXT NOT NULL,
              dailySpendLimit REAL NOT NULL
            )
          ''');
        }
      },
    );
  }

  // --- Transactions ---

  static Future<List<TransactionModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? categoryId,
    int? limit,
  }) async {
    final db = await database;
    if (db == null) {
      await _loadWebStorage();
      var list = List<TransactionModel>.from(_memoryTransactions ?? []);
      if (startDate != null) list = list.where((t) => t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)).toList();
      if (endDate != null) list = list.where((t) => t.date.isBefore(endDate) || t.date.isAtSameMomentAs(endDate)).toList();
      if (type != null) list = list.where((t) => t.type.name == type).toList();
      if (categoryId != null) list = list.where((t) => t.categoryId == categoryId).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      if (limit != null && list.length > limit) return list.sublist(0, limit);
      return list;
    }

    final where = <String>[];
    final args = <dynamic>[];

    if (startDate != null) {
      where.add('date >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      where.add('date <= ?');
      args.add(endDate.toIso8601String());
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (categoryId != null) {
      where.add('categoryId = ?');
      args.add(categoryId);
    }

    final result = await db.query(
      'transactions',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'date DESC, createdAt DESC',
      limit: limit,
    );

    return result.map((m) => TransactionModel.fromMap(m)).toList();
  }

  static Future<void> insertTransaction(TransactionModel txn) async {
    final db = await database;
    if (db == null) {
      await _loadWebStorage();
      _memoryTransactions!.removeWhere((t) => t.id == txn.id);
      _memoryTransactions!.add(txn);
      await _saveWebStorage();
      return;
    }
    await db.insert('transactions', txn.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateTransaction(TransactionModel txn) async {
    final db = await database;
    if (db == null) {
      await _loadWebStorage();
      final index = _memoryTransactions!.indexWhere((t) => t.id == txn.id);
      if (index != -1) _memoryTransactions![index] = txn;
      await _saveWebStorage();
      return;
    }
    await db.update('transactions', txn.toMap(), where: 'id = ?', whereArgs: [txn.id]);
  }

  static Future<void> deleteTransaction(String id) async {
    final db = await database;
    if (db == null) {
      await _loadWebStorage();
      _memoryTransactions!.removeWhere((t) => t.id == id);
      await _saveWebStorage();
      return;
    }
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Categories ---

  static Future<List<CategoryModel>> getCategories({bool? isIncome}) async {
    final db = await database;
    if (db == null) {
      await _loadWebStorage();
      if (isIncome != null) {
        return _memoryCategories!.where((c) => c.isIncome == isIncome).toList();
      }
      return List.from(_memoryCategories!);
    }

    final result = await db.query(
      'categories',
      where: isIncome != null ? 'isIncome = ?' : null,
      whereArgs: isIncome != null ? [isIncome ? 1 : 0] : null,
    );
    return result.map((m) => CategoryModel.fromMap(m)).toList();
  }

  static Future<void> insertCategory(CategoryModel cat) async {
    final db = await database;
    if (db == null) {
      await _loadWebStorage();
      _memoryCategories!.removeWhere((c) => c.id == cat.id);
      _memoryCategories!.add(cat);
      await _saveWebStorage();
      return;
    }
    await db.insert('categories', cat.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> deleteCategory(String id) async {
    final db = await database;
    if (db == null) {
      await _loadWebStorage();
      _memoryCategories!.removeWhere((c) => c.id == id);
      await _saveWebStorage();
      return;
    }
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- Aggregates ---

  static Future<double> getTotalByType(String type, {DateTime? startDate, DateTime? endDate}) async {
    final list = await getTransactions(startDate: startDate, endDate: endDate, type: type);
    double sum = 0.0;
    for (final t in list) {
      sum += t.amount;
    }
    return sum;
  }

  static Future<Map<String, double>> getCategoryTotals(String type, {DateTime? startDate, DateTime? endDate}) async {
    final list = await getTransactions(startDate: startDate, endDate: endDate, type: type);
    final map = <String, double>{};
    for (final t in list) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  static Future<List<Map<String, dynamic>>> getDailyTotals(String type, {required DateTime startDate, required DateTime endDate}) async {
    final list = await getTransactions(startDate: startDate, endDate: endDate, type: type);
    final map = <String, double>{};
    for (final t in list) {
      final dayStr = t.date.toIso8601String().substring(0, 10);
      map[dayStr] = (map[dayStr] ?? 0) + t.amount;
    }
    final result = map.entries.map((e) => {'day': e.key, 'total': e.value}).toList();
    result.sort((a, b) => (a['day'] as String).compareTo(b['day'] as String));
    return result;
  }

  // --- Active Budget Plan Goal ---

  static Future<Map<String, dynamic>?> getActiveGoal() async {
    final db = await database;
    if (db == null) {
      final prefs = await SharedPreferences.getInstance();
      final goalStr = prefs.getString(_spGoalKey);
      if (goalStr != null && goalStr.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(goalStr));
      }
      return null;
    }

    final result = await db.query('goals', limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  static Future<void> saveActiveGoal(Map<String, dynamic> goalData) async {
    final db = await database;
    if (db == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_spGoalKey, jsonEncode(goalData));
      return;
    }
    await db.delete('goals');
    await db.insert('goals', goalData, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
