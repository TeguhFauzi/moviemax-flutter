import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction_model.dart';
import '../services/database_service.dart';
import 'add_transaction_screen.dart';
import 'smart_budget_planner_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _formatMonth(DateTime date, String lang) {
    final locale = lang == 'ID' ? 'id_ID' : 'en_US';
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final budget = Provider.of<BudgetProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return SafeArea(
      child: budget.isLoading
          ? Center(child: CircularProgressIndicator(color: settings.primaryColor))
          : RefreshIndicator(
              onRefresh: () => budget.init(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [settings.primaryColor, const Color(0xFF818CF8)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              settings.tr('app_title'),
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: settings.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        // Month selector
                        GestureDetector(
                          onTap: () => _pickMonth(context, budget, settings),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: settings.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: settings.cardBorderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month, size: 16, color: settings.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  _formatMonth(budget.selectedMonth, settings.language),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: settings.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [settings.primaryColor, const Color(0xFF818CF8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: settings.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.tr('total_balance'),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(budget.balance),
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMiniStat(
                                  icon: Icons.arrow_downward_rounded,
                                  label: settings.tr('income'),
                                  amount: _formatCurrency(budget.totalIncome),
                                  color: const Color(0xFF4ADE80),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildMiniStat(
                                  icon: Icons.arrow_upward_rounded,
                                  label: settings.tr('expense'),
                                  amount: _formatCurrency(budget.totalExpense),
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Smart Suggestion Card for Today
                    _buildTodaySmartSuggestionCard(budget, settings),

                    const SizedBox(height: 24),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                              );
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: Text(settings.tr('add_transaction')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: settings.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SmartBudgetPlannerScreen()),
                              );
                            },
                            icon: const Icon(Icons.psychology_rounded),
                            label: const Text('Smart Planner'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: settings.primaryColor,
                              side: BorderSide(color: settings.primaryColor, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Expense by Category (top 5)
                    if (budget.expenseByCategory.isNotEmpty) ...[
                      Text(
                        settings.tr('expense_by_category'),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: settings.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...budget.expenseByCategory.entries.take(5).map((entry) {
                        final cat = budget.getCategoryById(entry.key);
                        final pct = budget.totalExpense > 0 ? entry.value / budget.totalExpense : 0.0;
                        return _buildCategoryBar(
                          name: cat?.name ?? entry.key,
                          icon: cat?.icon ?? Icons.category,
                          color: cat?.color ?? Colors.grey,
                          amount: _formatCurrency(entry.value),
                          percentage: pct,
                          settings: settings,
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // Recent Transactions
                    Text(
                      settings.tr('recent_transactions'),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: settings.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (budget.transactions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: settings.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: settings.cardBorderColor),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 48, color: settings.textMutedColor),
                            const SizedBox(height: 12),
                            Text(
                              settings.tr('no_transactions'),
                              style: GoogleFonts.inter(color: settings.textSecondaryColor, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else
                      ...budget.transactions.take(8).map((txn) => _buildTransactionTile(txn, budget, settings)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTodaySmartSuggestionCard(BudgetProvider budget, SettingsProvider settings) {
    final now = DateTime.now();
    
    // Cycle runs from 25th of current/prev month up to 25th of next/current month
    final DateTime cycleEnd = now.day > 25
        ? DateTime(now.year, now.month + 1, 25)
        : DateTime(now.year, now.month, 25);

    final todayDate = DateTime(now.year, now.month, now.day);
    final remainingDays = (cycleEnd.difference(todayDate).inDays + 1).clamp(1, 31);

    // Calculate current remaining balance and today's dynamic safe limit
    final balance = budget.balance > 0 ? budget.balance : 0.0;
    final dailyRecommended = balance / remainingDays;

    // Calculate today's actual expenses
    final todayExpenses = budget.transactions
        .where((t) => t.type == TransactionType.expense && t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)
        .fold(0.0, (sum, t) => sum + t.amount);

    final isOverbudgetToday = todayExpenses > dailyRecommended && dailyRecommended > 0;
    final statusColor = isOverbudgetToday ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    final remainingText = settings.language == 'ID'
        ? '${settings.tr('remaining_days_prefix')} $remainingDays ${settings.tr('remaining_days_suffix')}'
        : '$remainingDays ${settings.tr('remaining_days_suffix')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: settings.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverbudgetToday ? const Color(0xFFEF4444).withValues(alpha: 0.5) : settings.cardBorderColor,
          width: isOverbudgetToday ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOverbudgetToday ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.tr('smart_suggestion_title'),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
                    ),
                    Text(
                      remainingText,
                      style: GoogleFonts.inter(fontSize: 11, color: settings.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isOverbudgetToday ? settings.tr('status_overbudget') : settings.tr('status_safe'),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>?>(
            future: DatabaseService.getActiveGoal(),
            builder: (context, snapshot) {
              final goal = snapshot.data;
              if (goal == null) return const SizedBox.shrink();
              final targetSavings = (goal['targetSavings'] as num?)?.toDouble() ?? 0.0;
              final goalBalance = (goal['balance'] as num?)?.toDouble() ?? balance;
              final safeToSpendTotal = (goalBalance - targetSavings).clamp(0.0, double.infinity);
              final goalDailySpendLimit = safeToSpendTotal / remainingDays;
              final goalMakanAlloc = goalDailySpendLimit * 0.60;
              final goalRokokAlloc = goalDailySpendLimit * 0.25;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: settings.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: settings.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag_rounded, size: 16, color: settings.accentColor),
                            const SizedBox(width: 6),
                            Text(
                              settings.tr('target_goal_savings'),
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: settings.textPrimaryColor),
                            ),
                          ],
                        ),
                        Text(
                          _formatCurrency(targetSavings),
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: settings.accentColor),
                        ),
                      ],
                    ),
                  ),

                  // Goal Expense Suggestion Breakdown
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: settings.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: settings.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 16, color: settings.primaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                settings.tr('goal_expense_suggestion_title'),
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: settings.primaryColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              settings.tr('goal_daily_limit_label'),
                              style: GoogleFonts.inter(fontSize: 12, color: settings.textSecondaryColor),
                            ),
                            Text(
                              '${_formatCurrency(goalDailySpendLimit)} / ${settings.tr('per_day')}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.restaurant, size: 13, color: settings.primaryColor),
                                const SizedBox(width: 4),
                                Text('${settings.tr('food_label')}: ${_formatCurrency(goalMakanAlloc)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: settings.textPrimaryColor)),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.smoking_rooms, size: 13, color: settings.primaryColor),
                                const SizedBox(width: 4),
                                Text('${settings.tr('cigarette_label')}: ${_formatCurrency(goalRokokAlloc)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: settings.textPrimaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Divider(color: settings.cardBorderColor),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(settings.tr('daily_spend_limit'), style: GoogleFonts.inter(fontSize: 11, color: settings.textSecondaryColor)),
                  Text(
                    _formatCurrency(dailyRecommended),
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: settings.primaryColor),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(settings.tr('spent_today'), style: GoogleFonts.inter(fontSize: 11, color: settings.textSecondaryColor)),
                  Text(
                    _formatCurrency(todayExpenses),
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: isOverbudgetToday ? statusColor : settings.textPrimaryColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: settings.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant, size: 13, color: settings.primaryColor),
                    const SizedBox(width: 4),
                    Text('${settings.tr('food_label')}: ${_formatCurrency(dailyRecommended * 0.60)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: settings.textPrimaryColor)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.smoking_rooms, size: 13, color: settings.primaryColor),
                    const SizedBox(width: 4),
                    Text('${settings.tr('cigarette_label')}: ${_formatCurrency(dailyRecommended * 0.25)}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: settings.textPrimaryColor)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.white70)),
                Text(
                  amount,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar({
    required String name,
    required IconData icon,
    required Color color,
    required String amount,
    required double percentage,
    required SettingsProvider settings,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: settings.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: settings.cardBorderColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: settings.textPrimaryColor)),
                ),
                Text(amount, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: settings.textPrimaryColor)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: settings.cardBorderColor,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel txn, BudgetProvider budget, SettingsProvider settings) {
    final cat = budget.getCategoryById(txn.categoryId);
    final isIncome = txn.type == TransactionType.income;
    final color = isIncome ? settings.incomeColor : settings.expenseColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: settings.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: settings.cardBorderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (cat?.color ?? Colors.grey).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat?.icon ?? Icons.category, color: cat?.color ?? Colors.grey, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.title,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: settings.textPrimaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cat?.name ?? txn.categoryId} • ${DateFormat('dd MMM').format(txn.date)}',
                    style: GoogleFonts.inter(fontSize: 11, color: settings.textSecondaryColor),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'} ${_formatCurrency(txn.amount)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickMonth(BuildContext context, BudgetProvider budget, SettingsProvider settings) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: budget.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      budget.setMonth(picked);
    }
  }
}
