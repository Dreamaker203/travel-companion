import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_data.dart';
import '../data/repositories/expense_repository.dart';
import '../models/expense.dart';

final expenseRepoProvider = Provider<ExpenseRepository>((ref) {
  return AppData().expenseRepo;
});

class ExpenseListNotifier
    extends FamilyAsyncNotifier<List<Expense>, String> {
  @override
  Future<List<Expense>> build(String tripId) async {
    final repo = ref.read(expenseRepoProvider);
    return repo.getExpensesByTrip(tripId);
  }

  Future<Expense> createExpense({
    required double amount,
    String currency = 'CNY',
    ExpenseCategory category = ExpenseCategory.other,
    String paidBy = 'self',                      // 新加
    String splitMethod = 'aa',                   // 新加（备用）
    List<String> splitMembers = const [],        // 新加（备用）
    String note = '',
    DateTime? occurredAt,
  }) async {
    final repo = ref.read(expenseRepoProvider);
    final expense = await repo.createExpense(
      tripId: arg,
      amount: amount,
      currency: currency,
      category: category,
      paidBy: paidBy,
      splitMethod: splitMethod,
      splitMembers: splitMembers,
      note: note,
      occurredAt: occurredAt,
    );
    ref.invalidateSelf();
    return expense;
  }

  Future<void> updateExpense(Expense expense) async {
    final repo = ref.read(expenseRepoProvider);
    await repo.updateExpense(expense);
    ref.invalidateSelf();
  }

  Future<void> deleteExpense(String id) async {
    final repo = ref.read(expenseRepoProvider);
    await repo.deleteExpense(id);
    ref.invalidateSelf();
  }
}

final expenseListProvider =
    AsyncNotifierProvider.family<ExpenseListNotifier, List<Expense>, String>(
  ExpenseListNotifier.new,
);