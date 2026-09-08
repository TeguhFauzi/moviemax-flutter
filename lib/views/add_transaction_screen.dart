import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/budget_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? existing;

  const AddTransactionScreen({Key? key, this.existing}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.existing!;
      _titleController.text = e.title;
      _amountController.text = e.amount.toStringAsFixed(0);
      _noteController.text = e.note ?? '';
      _type = e.type;
      _selectedCategoryId = e.categoryId;
      _selectedDate = e.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final budget = Provider.of<BudgetProvider>(context);
    final categories = _type == TransactionType.income ? budget.incomeCategories : budget.expenseCategories;

    // Reset category if switching type and current category doesn't match
    if (_selectedCategoryId != null) {
      final catExists = categories.any((c) => c.id == _selectedCategoryId);
      if (!catExists) _selectedCategoryId = null;
    }

    return Scaffold(
      backgroundColor: settings.backgroundColor,
      appBar: AppBar(
        backgroundColor: settings.surfaceColor,
        foregroundColor: settings.textPrimaryColor,
        elevation: 0,
        title: Text(
          _isEditing ? settings.tr('edit_transaction') : settings.tr('add_transaction'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_rounded, color: settings.dangerColor),
              onPressed: () => _confirmDelete(context, budget, settings),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: settings.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: settings.cardBorderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = TransactionType.expense),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _type == TransactionType.expense
                                ? settings.expenseColor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              settings.tr('expense'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: _type == TransactionType.expense
                                    ? settings.expenseColor
                                    : settings.textMutedColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = TransactionType.income),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _type == TransactionType.income
                                ? settings.incomeColor.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              settings.tr('income'),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: _type == TransactionType.income
                                    ? settings.incomeColor
                                    : settings.textMutedColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              _buildLabel(settings.tr('title'), settings),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(color: settings.textPrimaryColor),
                decoration: _inputDecoration(settings, settings.tr('title')),
                validator: (v) => (v == null || v.trim().isEmpty) ? settings.tr('title_required') : null,
              ),
              const SizedBox(height: 16),

              // Amount
              _buildLabel(settings.tr('amount'), settings),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                style: GoogleFonts.inter(color: settings.textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final clean = val.replaceAll(RegExp(r'[^\d]'), '');
                  if (clean.isEmpty) {
                    _amountController.value = const TextEditingValue(text: '');
                    return;
                  }
                  final number = double.tryParse(clean);
                  if (number != null) {
                    final formatted = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(number).trim();
                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                decoration: _inputDecoration(settings, '0').copyWith(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rp',
                          style: GoogleFonts.inter(color: settings.textSecondaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return settings.tr('amount_required');
                  final clean = v.replaceAll(RegExp(r'[^\d]'), '');
                  final parsed = double.tryParse(clean);
                  if (parsed == null || parsed <= 0) return settings.tr('amount_invalid');
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              _buildLabel(settings.tr('category'), settings),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) => _buildCategoryChip(cat, settings)).toList(),
              ),
              const SizedBox(height: 16),

              // Date
              _buildLabel(settings.tr('date'), settings),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _pickDate(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: settings.inputFillColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: settings.cardBorderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: settings.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMMM yyyy', settings.language == 'ID' ? 'id_ID' : 'en_US').format(_selectedDate),
                        style: GoogleFonts.inter(fontSize: 14, color: settings.textPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              _buildLabel(settings.tr('note'), settings),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                style: GoogleFonts.inter(color: settings.textPrimaryColor),
                maxLines: 3,
                decoration: _inputDecoration(settings, settings.tr('note')),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _save(context, budget, settings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: settings.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: Text(settings.tr('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, SettingsProvider settings) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: settings.textSecondaryColor,
      ),
    );
  }

  InputDecoration _inputDecoration(SettingsProvider settings, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: settings.textMutedColor),
      filled: true,
      fillColor: settings.inputFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: settings.cardBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: settings.cardBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: settings.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildCategoryChip(CategoryModel cat, SettingsProvider settings) {
    final selected = _selectedCategoryId == cat.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = cat.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cat.color.withValues(alpha: 0.2) : settings.inputFillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cat.color : settings.cardBorderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, size: 16, color: cat.color),
            const SizedBox(width: 6),
            Text(
              cat.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? cat.color : settings.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save(BuildContext context, BudgetProvider budget, SettingsProvider settings) async {
    if (!_formKey.currentState!.validate()) return;
    
    final categories = _type == TransactionType.income ? budget.incomeCategories : budget.expenseCategories;
    final catId = _selectedCategoryId ?? (categories.isNotEmpty ? categories.first.id : 'other');


    final amount = double.parse(_amountController.text.replaceAll('.', '').replaceAll(',', ''));

    if (_isEditing) {
      final updated = widget.existing!.copyWith(
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        categoryId: catId,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        date: _selectedDate,
      );
      await budget.updateTransaction(updated);
    } else {
      await budget.addTransaction(
        title: _titleController.text.trim(),
        amount: amount,
        type: _type,
        categoryId: catId,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        date: _selectedDate,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context, BudgetProvider budget, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: settings.surfaceColor,
        title: Text(settings.tr('delete'), style: GoogleFonts.outfit(color: settings.textPrimaryColor)),
        content: Text(settings.tr('delete_confirm'), style: GoogleFonts.inter(color: settings.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(settings.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await budget.deleteTransaction(widget.existing!.id);
              if (mounted) Navigator.pop(context);
            },
            child: Text(settings.tr('delete'), style: TextStyle(color: settings.dangerColor)),
          ),
        ],
      ),
    );
  }
}
