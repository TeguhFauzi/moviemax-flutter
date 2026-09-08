class SmartBudgetPlan {
  final double currentBalance;
  final double targetSavings;
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final double safeToSpendTotal;
  final double dailySpendLimit;
  final Map<String, double> categoryBudgets;

  SmartBudgetPlan({
    required this.currentBalance,
    required this.targetSavings,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.safeToSpendTotal,
    required this.dailySpendLimit,
    required this.categoryBudgets,
  });

  factory SmartBudgetPlan.calculate({
    required double balance,
    required double targetSavings,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, double>? customCategoryWeights,
  }) {
    final diff = endDate.difference(startDate).inDays + 1;
    final daysCount = diff > 0 ? diff : 1;

    final safeTotal = (balance - targetSavings).clamp(0.0, balance);
    final dailyLimit = safeTotal / daysCount;

    // Standard allocation weights: Makan (60%), Rokok (25%), Lainnya (15%)
    final weights = customCategoryWeights ?? {
      'Makan & Minum': 0.60,
      'Rokok': 0.25,
      'Kebutuhan Lain': 0.15,
    };

    final budgets = <String, double>{};
    weights.forEach((cat, weight) {
      budgets[cat] = safeTotal * weight;
    });

    return SmartBudgetPlan(
      currentBalance: balance,
      targetSavings: targetSavings,
      startDate: startDate,
      endDate: endDate,
      days: daysCount,
      safeToSpendTotal: safeTotal,
      dailySpendLimit: dailyLimit,
      categoryBudgets: budgets,
    );
  }
}
