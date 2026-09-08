import 'package:flutter_test/flutter_test.dart';
import 'package:budget_manager/models/transaction_model.dart';

void main() {
  test('TransactionModel toMap/fromMap roundtrip', () {
    final txn = TransactionModel(
      id: 'test-1',
      title: 'Makan Siang',
      amount: 25000,
      type: TransactionType.expense,
      categoryId: 'food',
      date: DateTime(2026, 1, 15),
    );

    final map = txn.toMap();
    final restored = TransactionModel.fromMap(map);

    expect(restored.id, txn.id);
    expect(restored.title, txn.title);
    expect(restored.amount, txn.amount);
    expect(restored.type, txn.type);
    expect(restored.categoryId, txn.categoryId);
  });
}
