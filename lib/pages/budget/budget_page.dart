import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../providers/expense_providers.dart';
import '../../theme/app_theme.dart';
import 'expense_edit_page.dart';
import '../companions/companions_page.dart';
import '../settlement/settlement_page.dart';

class BudgetPage extends ConsumerWidget {
  final Trip trip;
  const BudgetPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider(trip.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '预算',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              trip.title,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, size: 20),
            tooltip: '同行者',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanionsPage(tripId: trip.id),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 20),
            tooltip: '账单结算',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettlementPage(tripId: trip.id),
                ),
              );
            },
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('加载失败：$e',
              style: const TextStyle(color: Colors.red)),
        ),
        data: (expenses) => _buildContent(context, ref, expenses),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseEditPage(tripId: trip.id),
            ),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '记一笔',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, List<Expense> expenses) {
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final budget = trip.totalBudget;
    final remaining = budget - total;
    final percent = budget > 0 ? (total / budget).clamp(0.0, 1.0) : 0.0;
    final isOver = budget > 0 && total > budget;

    final tripDays = trip.totalDays;
    final now = DateTime.now();
    final daysLeft = trip.endDate.difference(now).inDays.clamp(0, tripDays);

    // 按类别汇总
    final byCategory = <ExpenseCategory, double>{};
    for (final c in ExpenseCategory.values) {
      byCategory[c] = 0;
    }
    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        _buildOverviewCard(total, budget, remaining, percent, daysLeft, isOver),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '分类支出',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...byCategory.entries
            .where((e) => e.value > 0)
            .map((e) => _buildCategoryRow(e.key, e.value, total)),
        if (expenses.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '最近的支出',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...expenses.take(8).map((e) => _buildExpenseTile(context, e)),
        ],
      ],
    );
  }

  Widget _buildOverviewCard(double total, double budget, double remaining,
      double percent, int daysLeft, bool isOver) {
    final hasBudget = budget > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasBudget ? '已用 / 预算' : '总支出',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.primaryLight,
                ),
              ),
              if (hasBudget)
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOver ? Colors.red : AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '¥ ${total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: isOver ? Colors.red : AppTheme.primary,
                ),
              ),
              if (hasBudget)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 6),
                  child: Text(
                    '/ ¥ ${budget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
            ],
          ),
          if (hasBudget) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor: const Color(0xFFCECBF6),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? Colors.red : AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isOver
                      ? '超支 ¥ ${(-remaining).toStringAsFixed(0)}'
                      : '剩余 ¥ ${remaining.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOver ? Colors.red : AppTheme.primaryLight,
                  ),
                ),
                Text(
                  daysLeft > 0 ? '剩 $daysLeft 天' : '旅行已结束',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
      ExpenseCategory category, double amount, double total) {
    final percent = total > 0 ? amount / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, size: 16, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '¥ ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 4,
                    backgroundColor: AppTheme.background,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(category.color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, Expense e) {
    final dateFmt = DateFormat('M/d HH:mm');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExpenseEditPage(
                tripId: trip.id,
                existing: e,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: e.category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(e.category.icon, size: 14, color: e.category.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.note.isEmpty ? e.category.label : e.note,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${e.category.label} · ${dateFmt.format(e.occurredAt)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '¥ ${e.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}