import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/database_service.dart';

class BudgetProvider extends ChangeNotifier {
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<String, double> _expenseByCat = {};
  Map<String, double> _incomeByCat = {};
  bool _isLoading = true;

  // Current month filter
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get expenseCategories => _categories.where((c) => !c.isIncome).toList();
  List<CategoryModel> get incomeCategories => _categories.where((c) => c.isIncome).toList();
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _totalIncome - _totalExpense;
  Map<String, double> get expenseByCategory => _expenseByCat;
  Map<String, double> get incomeByCategory => _incomeByCat;
  bool get isLoading => _isLoading;
  DateTime get selectedMonth => _selectedMonth;

  DateTime get _monthStart => DateTime(_selectedMonth.year, _selectedMonth.month);
  DateTime get _monthEnd => DateTime(_selectedMonth.year, _selectedMonth.month + 1).subtract(const Duration(milliseconds: 1));

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await DatabaseService.getCategories();
      await _refreshData();
    } catch (e) {
      debugPrint('Error initializing budget data: $e');
      _categories = CategoryModel.defaults;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month);
    await _refreshData();
    notifyListeners();
  }

  Future<void> _refreshData() async {
    try {
      _transactions = await DatabaseService.getTransactions(
        startDate: _monthStart,
        endDate: _monthEnd,
      );
      _totalIncome = await DatabaseService.getTotalByType('income', startDate: _monthStart, endDate: _monthEnd);
      _totalExpense = await DatabaseService.getTotalByType('expense', startDate: _monthStart, endDate: _monthEnd);
      _expenseByCat = await DatabaseService.getCategoryTotals('expense', startDate: _monthStart, endDate: _monthEnd);
      _incomeByCat = await DatabaseService.getCategoryTotals('income', startDate: _monthStart, endDate: _monthEnd);
    } catch (e) {
      debugPrint('Error fetching database data: $e');
      _transactions = [];
      _totalIncome = 0;
      _totalExpense = 0;
      _expenseByCat = {};
      _incomeByCat = {};
    }
  }

  Future<void> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String categoryId,
    String? note,
    required DateTime date,
  }) async {
    final txn = TransactionModel(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      type: type,
      categoryId: categoryId,
      note: note,
      date: date,
    );
    await DatabaseService.insertTransaction(txn);
    await _refreshData();
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel txn) async {
    await DatabaseService.updateTransaction(txn);
    await _refreshData();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await DatabaseService.deleteTransaction(id);
    await _refreshData();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getDailyExpenses() async {
    return DatabaseService.getDailyTotals('expense', startDate: _monthStart, endDate: _monthEnd);
  }

  Future<List<Map<String, dynamic>>> getDailyIncome() async {
    return DatabaseService.getDailyTotals('income', startDate: _monthStart, endDate: _monthEnd);
  }

  // Get recent transactions (all months, limited)
  Future<List<TransactionModel>> getRecentTransactions({int limit = 5}) async {
    return DatabaseService.getTransactions(limit: limit);
  }
}
