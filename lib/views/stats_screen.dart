import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _showExpense = true;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final budget = Provider.of<BudgetProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    final categoryData = _showExpense ? budget.expenseByCategory : budget.incomeByCategory;
    final total = _showExpense ? budget.totalExpense : budget.totalIncome;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              settings.tr('stats_tab'),
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMMM yyyy', settings.language == 'ID' ? 'id_ID' : 'en_US').format(budget.selectedMonth),
              style: GoogleFonts.inter(fontSize: 14, color: settings.textSecondaryColor),
            ),
            const SizedBox(height: 20),

            // Summary cards
            Row(
              children: [
                Expanded(child: _buildSummaryCard(settings.tr('income'), budget.totalIncome, settings.incomeColor, settings)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryCard(settings.tr('expense'), budget.totalExpense, settings.expenseColor, settings)),
              ],
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(settings.tr('total_balance'), budget.balance, settings.primaryColor, settings),
            const SizedBox(height: 24),

            // Toggle expense/income
            Row(
              children: [
                Expanded(
                  child: Text(
                    _showExpense ? settings.tr('expense_by_category') : settings.tr('income_by_category'),
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showExpense = !_showExpense),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: settings.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: settings.cardBorderColor),
                    ),
                    child: Text(
                      _showExpense ? settings.tr('income') : settings.tr('expense'),
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: settings.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pie Chart
            if (categoryData.isNotEmpty) ...[
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieSections(categoryData, total, budget, settings),
                    centerSpaceRadius: 50,
                    sectionsSpace: 3,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category breakdown list
              ...categoryData.entries.map((entry) {
                final cat = budget.getCategoryById(entry.key);
                final pct = total > 0 ? (entry.value / total * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (cat?.color ?? Colors.grey).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cat?.icon ?? Icons.category, color: cat?.color ?? Colors.grey, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat?.name ?? entry.key, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: settings.textPrimaryColor)),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: settings.cardBorderColor,
                                  valueColor: AlwaysStoppedAnimation(cat?.color ?? Colors.grey),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_formatCurrency(entry.value), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: settings.textPrimaryColor)),
                            Text('${pct.toStringAsFixed(1)}%', style: GoogleFonts.inter(fontSize: 11, color: settings.textMutedColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else
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
                    Icon(Icons.pie_chart_outline, size: 48, color: settings.textMutedColor),
                    const SizedBox(height: 12),
                    Text(settings.tr('no_transactions'), style: GoogleFonts.inter(color: settings.textSecondaryColor)),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Daily expense chart
            Text(
              settings.tr('daily_chart'),
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: settings.textPrimaryColor),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _showExpense ? budget.getDailyExpenses() : budget.getDailyIncome(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(settings.tr('no_transactions'), style: GoogleFonts.inter(color: settings.textMutedColor)),
                    );
                  }
                  return _buildBarChart(snapshot.data!, settings);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, double amount, Color color, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: settings.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: settings.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: settings.textSecondaryColor)),
          const SizedBox(height: 6),
          Text(
            _formatCurrency(amount),
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, double> data,
    double total,
    BudgetProvider budget,
    SettingsProvider settings,
  ) {
    return data.entries.map((entry) {
      final cat = budget.getCategoryById(entry.key);
      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
      return PieChartSectionData(
        value: entry.value,
        color: cat?.color ?? Colors.grey,
        radius: 35,
        title: '${pct.toStringAsFixed(0)}%',
        titleStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, SettingsProvider settings) {
    final color = _showExpense ? settings.expenseColor : settings.incomeColor;
    final maxVal = data.fold<double>(0, (prev, e) {
      final v = (e['total'] as num).toDouble();
      return v > prev ? v : prev;
    });

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final day = data[group.x.toInt()]['day'] as String;
              return BarTooltipItem(
                '$day\n${_formatCurrency(rod.toY)}',
                GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                final day = (data[idx]['day'] as String).substring(8);
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(day, style: GoogleFonts.inter(fontSize: 9, color: settings.textMutedColor)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          final val = (data[i]['total'] as num).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: color,
                width: data.length > 15 ? 6 : 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
