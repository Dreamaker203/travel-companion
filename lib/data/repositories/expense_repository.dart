import 'dart:convert';
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
    String paidBy = 'self',
    String splitMethod = 'aa',
    List<String> splitMembers = const [],
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
      paidBy: Value(paidBy),
      splitMethod: Value(splitMethod),
      splitMembers: Value(jsonEncode(splitMembers)),
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
      paidBy: Value(expense.paidBy),
      splitMethod: Value(expense.splitMethod),
      splitMembers: Value(jsonEncode(expense.splitMembers)),
      note: Value(expense.note),
      occurredAt: Value(expense.occurredAt),
    ));
  }

  Future<void> deleteExpense(String id) async {
    await (_db.delete(_db.expenses)..where((e) => e.id.equals(id))).go();
  }

  Expense _toModel(db.Expense row) {
    List<String> members = const [];
    try {
      final decoded = jsonDecode(row.splitMembers);
      if (decoded is List) {
        members = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // JSON 解析失败就用空数组，不阻塞
    }

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
      paidBy: row.paidBy,
      splitMethod: row.splitMethod,
      splitMembers: members,
      note: row.note,
      occurredAt: row.occurredAt,
      createdAt: row.createdAt,
    );
  }
}