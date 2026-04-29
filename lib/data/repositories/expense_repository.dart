import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart' as db;
import '../../models/expense.dart';

class ExpenseRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  ExpenseRepository(this._db);

  Future<List<Expense>> getExpensesByTrip(String tripId) async {
    final query = _db.select(_db.expenses)
      ..where((e) => e.tripId.equals(tripId))
      ..orderBy([(e) => OrderingTerm.desc(e.occurredAt)]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  Future<Expense> createExpense({
    required String tripId,
    String? activityId,
    required double amount,
    String currency = 'CNY',
    ExpenseCategory category = ExpenseCategory.other,
    String note = '',
    DateTime? occurredAt,
  }) async {
    final id = _uuid.v4();
    final companion = db.ExpensesCompanion.insert(
      id: id,
      tripId: tripId,
      activityId: Value(activityId),
      amount: amount,
      currency: Value(currency),
      category: Value(category.name),
      note: Value(note),
      occurredAt: Value(occurredAt ?? DateTime.now()),
    );
    await _db.into(_db.expenses).insert(companion);
    final row = await (_db.select(_db.expenses)..where((e) => e.id.equals(id)))
        .getSingle();
    return _toModel(row);
  }

  Future<void> updateExpense(Expense expense) async {
    await (_db.update(_db.expenses)..where((e) => e.id.equals(expense.id)))
        .write(db.ExpensesCompanion(
      amount: Value(expense.amount),
      currency: Value(expense.currency),
      category: Value(expense.category.name),
      note: Value(expense.note),
      occurredAt: Value(expense.occurredAt),
    ));
  }

  Future<void> deleteExpense(String id) async {
    await (_db.delete(_db.expenses)..where((e) => e.id.equals(id))).go();
  }

  Expense _toModel(db.Expense row) {
    return Expense(
      id: row.id,
      tripId: row.tripId,
      activityId: row.activityId,
      amount: row.amount,
      currency: row.currency,
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == row.category,
        orElse: () => ExpenseCategory.other,
      ),
      note: row.note,
      occurredAt: row.occurredAt,
      createdAt: row.createdAt,
    );
  }
}