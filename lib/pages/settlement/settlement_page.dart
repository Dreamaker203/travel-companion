import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/companion_providers.dart';
import '../../providers/expense_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/settlement_calculator.dart';

class SettlementPage extends ConsumerWidget {
  final String tripId;
  const SettlementPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListProvider(tripId));
    final companionsAsync = ref.watch(companionListProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '账单结算',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (expenses) {
          return companionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败：$e')),
            data: (companions) {
              if (expenses.isEmpty) {
                return _buildEmpty('还没有支出记录');
              }

              final result = SettlementCalculator.calculate(
                expenses: expenses,
                companions: companions,
                selfName: '我',
              );

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(result),
                  const SizedBox(height: 18),
                  _buildBalanceTable(result),
                  const SizedBox(height: 18),
                  _buildTransferPlan(result),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: AppTheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(SettlementResult r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '总支出',
            style: TextStyle(fontSize: 11, color: AppTheme.primaryLight),
          ),
          const SizedBox(height: 4),
          Text(
            '¥ ${r.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '人均 ¥ ${r.perPersonAmount.toStringAsFixed(2)} · ${r.balances.length} 人',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceTable(SettlementResult r) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 表头
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('成员',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500))),
                Expanded(
                    child: Text('垫付',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500))),
                Expanded(
                    child: Text('应付',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500))),
                Expanded(
                    child: Text('差额',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          // 每行
          ...r.balances.map((b) {
            final diffColor = b.diff > 0.01
                ? const Color(0xFF0F6E56)
                : (b.diff < -0.01 ? Colors.red : AppTheme.textSecondary);
            final diffPrefix =
                b.diff > 0.01 ? '+' : (b.diff < -0.01 ? '−' : '');
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      b.name,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '¥${b.paid.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '¥${b.owed.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$diffPrefix¥${b.diff.abs().toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: diffColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransferPlan(SettlementResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '最简转账方案',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.transfers.isEmpty
                    ? '已结清'
                    : '${r.transfers.length} 笔',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (r.transfers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                '所有人都已结清，无需转账',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.primary,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                ...r.transfers.map((t) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(
                              t.fromName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward,
                              size: 14, color: AppTheme.primary),
                          Expanded(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '¥ ${t.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward,
                              size: 14, color: AppTheme.primary),
                          SizedBox(
                            width: 70,
                            child: Text(
                              t.toName,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                const Divider(color: Color(0x40534AB7), height: 1),
                const SizedBox(height: 8),
                Text(
                  '仅需 ${r.transfers.length} 笔转账即可结清全部账目',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}