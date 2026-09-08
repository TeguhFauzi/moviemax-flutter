import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isIncome;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isIncome,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'iconCode': icon.codePoint,
        'colorValue': color.toARGB32(),
        'isIncome': isIncome ? 1 : 0,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    // ignore: non_const_argument_for_const_parameter
    final icon = IconData(map['iconCode'] as int, fontFamily: 'MaterialIcons');
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: icon,
      color: Color(map['colorValue'] as int),
      isIncome: (map['isIncome'] as int) == 1,
    );
  }

  // Default categories
  static List<CategoryModel> get defaults => [
        // Expense categories
        const CategoryModel(id: 'food', name: 'Makanan', icon: Icons.restaurant, color: Color(0xFFEF4444), isIncome: false),
        const CategoryModel(id: 'transport', name: 'Transportasi', icon: Icons.directions_car, color: Color(0xFFF59E0B), isIncome: false),
        const CategoryModel(id: 'shopping', name: 'Belanja', icon: Icons.shopping_bag, color: Color(0xFF8B5CF6), isIncome: false),
        const CategoryModel(id: 'bills', name: 'Tagihan', icon: Icons.receipt_long, color: Color(0xFFEC4899), isIncome: false),
        const CategoryModel(id: 'entertainment', name: 'Hiburan', icon: Icons.movie, color: Color(0xFF06B6D4), isIncome: false),
        const CategoryModel(id: 'health', name: 'Kesehatan', icon: Icons.local_hospital, color: Color(0xFF10B981), isIncome: false),
        const CategoryModel(id: 'education', name: 'Pendidikan', icon: Icons.school, color: Color(0xFF3B82F6), isIncome: false),
        const CategoryModel(id: 'other_expense', name: 'Lainnya', icon: Icons.more_horiz, color: Color(0xFF6B7280), isIncome: false),
        // Income categories
        const CategoryModel(id: 'salary', name: 'Gaji', icon: Icons.account_balance_wallet, color: Color(0xFF10B981), isIncome: true),
        const CategoryModel(id: 'freelance', name: 'Freelance', icon: Icons.laptop, color: Color(0xFF6366F1), isIncome: true),
        const CategoryModel(id: 'investment', name: 'Investasi', icon: Icons.trending_up, color: Color(0xFF14B8A6), isIncome: true),
        const CategoryModel(id: 'gift', name: 'Hadiah', icon: Icons.card_giftcard, color: Color(0xFFF59E0B), isIncome: true),
        const CategoryModel(id: 'other_income', name: 'Lainnya', icon: Icons.more_horiz, color: Color(0xFF6B7280), isIncome: true),
      ];
}
