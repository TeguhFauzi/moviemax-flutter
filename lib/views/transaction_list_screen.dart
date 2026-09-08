import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String _filter = 'all'; // all, income, expense

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final budget = Provider.of<BudgetProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    List<TransactionModel> filtered = budget.transactions;
    if (_filter == 'income') {
      filtered = filtered.where((t) => t.type == TransactionType.income).toList();
    } else if (_filter == 'expense') {
      filtered = filtered.where((t) => t.type == TransactionType.expense).toList();
    }

    // Group by date
    final grouped = <String, List<TransactionModel>>{};
    for (final txn in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(txn.date);
      grouped.putIfAbsent(key, () => []).add(txn);
    }

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  settings.tr('all_transactions'),
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: settings.textPrimaryColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle_rounded, color: settings.primaryColor, size: 32),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
                  },
                ),
              ],
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                _buildFilterChip('all', settings.tr('overview'), settings),
                const SizedBox(width: 8),
                _buildFilterChip('income', settings.tr('income'), settings),
                const SizedBox(width: 8),
                _buildFilterChip('expense', settings.tr('expense'), settings),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, size: 56, color: settings.textMutedColor),
                        const SizedBox(height: 12),
                        Text(
                          settings.tr('no_transactions'),
                          style: GoogleFonts.inter(color: settings.textSecondaryColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final dateKey = grouped.keys.elementAt(index);
                      final txns = grouped[dateKey]!;
                      final date = DateTime.parse(dateKey);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              DateFormat('EEEE, dd MMMM yyyy', settings.language == 'ID' ? 'id_ID' : 'en_US').format(date),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: settings.textSecondaryColor,
                              ),
                            ),
                          ),
                          ...txns.map((txn) => _buildTxnCard(txn, budget, settings)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, SettingsProvider settings) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? settings.primaryColor : settings.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? settings.primaryColor : settings.cardBorderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : settings.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTxnCard(TransactionModel txn, BudgetProvider budget, SettingsProvider settings) {
    final cat = budget.getCategoryById(txn.categoryId);
    final isIncome = txn.type == TransactionType.income;
    final color = isIncome ? settings.incomeColor : settings.expenseColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTransactionScreen(existing: txn)),
          );
        },
        child: Dismissible(
          key: Key(txn.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: settings.dangerColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: settings.surfaceColor,
                title: Text(settings.tr('delete'), style: GoogleFonts.outfit(color: settings.textPrimaryColor)),
                content: Text(settings.tr('delete_confirm'), style: GoogleFonts.inter(color: settings.textSecondaryColor)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(settings.tr('cancel'))),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(settings.tr('delete'), style: TextStyle(color: settings.dangerColor)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) => budget.deleteTransaction(txn.id),
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
                      if (txn.note != null && txn.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          txn.note!,
                          style: GoogleFonts.inter(fontSize: 11, color: settings.textMutedColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'} ${_formatCurrency(txn.amount)}',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                    ),
                    Text(
                      cat?.name ?? txn.categoryId,
                      style: GoogleFonts.inter(fontSize: 10, color: settings.textMutedColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
