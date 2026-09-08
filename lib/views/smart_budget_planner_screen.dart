import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';
import '../models/smart_budget_model.dart';
import '../services/database_service.dart';

class SmartBudgetPlannerScreen extends StatefulWidget {
  const SmartBudgetPlannerScreen({Key? key}) : super(key: key);

  @override
  State<SmartBudgetPlannerScreen> createState() => _SmartBudgetPlannerScreenState();
}

class _SmartBudgetPlannerScreenState extends State<SmartBudgetPlannerScreen> {
  final _balanceController = TextEditingController();
  final _savingsController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));

  SmartBudgetPlan? _plan;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budget = Provider.of<BudgetProvider>(context, listen: false);
      final realBalance = budget.balance > 0 ? budget.balance : 0.0;
      final defaultSavings = realBalance > 0 ? (realBalance * 0.2) : 0.0;
      _balanceController.text = _formatNumber(realBalance);
      _savingsController.text = _formatNumber(defaultSavings);
      _calculatePlan();
    });
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _formatNumber(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    return formatter.format(amount).trim();
  }

  void _formatFieldController(TextEditingController controller, String val) {
    final clean = val.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) {
      controller.value = const TextEditingValue(text: '');
      return;
    }
    final number = double.tryParse(clean);
    if (number != null) {
      final formatted = _formatNumber(number);
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _calculatePlan() {
    final balanceStr = _balanceController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final savingsStr = _savingsController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final balance = double.tryParse(balanceStr) ?? 0.0;
    final savings = double.tryParse(savingsStr) ?? 0.0;

    setState(() {
      _plan = SmartBudgetPlan.calculate(
        balance: balance,
        targetSavings: savings,
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _calculatePlan();
    }
  }

  Future<void> _saveGoal() async {
    if (_plan == null) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final goalData = {
      'id': 'active_goal',
      'balance': _plan!.currentBalance,
      'targetSavings': _plan!.targetSavings,
      'startDate': _plan!.startDate.toIso8601String(),
      'endDate': _plan!.endDate.toIso8601String(),
      'dailySpendLimit': _plan!.dailySpendLimit,
    };
    await DatabaseService.saveActiveGoal(goalData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(settings.tr('goal_saved_success')),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        title: Text(
          settings.tr('smart_planner_title'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
        ),
        backgroundColor: settings.surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: settings.textPrimaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: settings.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: settings.cardBorderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.tr('planning_target'),
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
                  ),
                  const SizedBox(height: 16),
                  
                  // Total Uang Tersisa
                  Text(settings.tr('current_balance_label'), style: GoogleFonts.inter(fontSize: 13, color: settings.textSecondaryColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _balanceController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _formatFieldController(_balanceController, val);
                      _calculatePlan();
                    },
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rp',
                              style: GoogleFonts.inter(color: settings.textSecondaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      filled: true,
                      fillColor: settings.inputFillColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Target Tabungan
                  Text(settings.tr('savings_target_label'), style: GoogleFonts.inter(fontSize: 13, color: settings.textSecondaryColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _savingsController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      _formatFieldController(_savingsController, val);
                      _calculatePlan();
                    },
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rp',
                              style: GoogleFonts.inter(color: settings.textSecondaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      filled: true,
                      fillColor: settings.inputFillColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rentang Tanggal
                  Text(settings.tr('period_duration_label'), style: GoogleFonts.inter(fontSize: 13, color: settings.textSecondaryColor)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: settings.inputFillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: settings.cardBorderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range_rounded, color: settings.primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: settings.textPrimaryColor),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: settings.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_plan?.days ?? 1} ${settings.tr('days_unit')}',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: settings.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Plan Recommendations
            if (_plan != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [settings.primaryColor, const Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      settings.tr('daily_limit_title'),
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatCurrency(_plan!.dailySpendLimit)} / ${settings.tr('per_day')}',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _summaryItem(settings.tr('safe_to_spend'), _formatCurrency(_plan!.safeToSpendTotal)),
                        _summaryItem(settings.tr('disimpan_savings'), _formatCurrency(_plan!.targetSavings)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Recommendations Breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: settings.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: settings.cardBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${settings.tr('daily_recommendation')} (${_plan!.days} ${settings.tr('days_unit')})',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
                    ),
                    const SizedBox(height: 14),

                    ..._plan!.categoryBudgets.entries.map((entry) {
                      final dailyCat = entry.value / (_plan!.days > 0 ? _plan!.days : 1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: settings.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                entry.key.contains('Makan')
                                    ? Icons.restaurant
                                    : entry.key.contains('Rokok')
                                        ? Icons.smoking_rooms
                                        : Icons.category,
                                size: 18,
                                color: settings.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: settings.textPrimaryColor)),
                                  Text('${_formatCurrency(dailyCat)} / ${settings.tr('per_day')}', style: GoogleFonts.inter(fontSize: 12, color: settings.textSecondaryColor)),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(entry.value),
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: settings.primaryColor),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveGoal,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(settings.tr('save_target_button')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: settings.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(val, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
