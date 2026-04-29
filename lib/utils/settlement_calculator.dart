import '../models/companion.dart';
import '../models/expense.dart';

/// 一笔结算转账（A 应该给 B 多少钱）
class Transfer {
  final String fromId; // 'self' 或 companionId
  final String fromName;
  final String toId;
  final String toName;
  final double amount;

  Transfer({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });

  @override
  String toString() => '$fromName → $toName: ¥${amount.toStringAsFixed(2)}';
}

/// 每个人的支出汇总（垫付了多少、应付多少、净差额）
class MemberBalance {
  final String id;
  final String name;
  final double paid;       // 实际垫付
  final double owed;       // 按 AA 应付
  double get diff => paid - owed; // >0 多付（应该收钱）, <0 少付（应该转钱）

  MemberBalance({
    required this.id,
    required this.name,
    required this.paid,
    required this.owed,
  });
}

/// AA 分摊结算计算器
///
/// 输入：旅行的所有支出 + 同行者列表
/// 输出：每人收支差额 + 最简转账方案
class SettlementCalculator {
  /// 主入口：基于支出和同行者，计算每人差额并生成最简转账方案
  ///
  /// [expenses] 该旅行的所有支出
  /// [companions] 该旅行的同行者
  /// [selfName] 组织者（你自己）显示的名字
  static SettlementResult calculate({
    required List<Expense> expenses,
    required List<TripCompanion> companions,
    String selfName = '我',
  }) {
    // ============ Step 1: 算每人的"垫付"和"应付" ============
    // 用 'self' 代表组织者自己，其他人用 companionId
    final allMemberIds = <String>['self', ...companions.map((c) => c.id)];
    final nameOf = <String, String>{
      'self': selfName,
      for (final c in companions) c.id: c.name,
    };

    final paid = <String, double>{for (final id in allMemberIds) id: 0};
    final owed = <String, double>{for (final id in allMemberIds) id: 0};

    for (final e in expenses) {
      // 谁付的
      final payer = e.paidBy.isEmpty ? 'self' : e.paidBy;
      paid[payer] = (paid[payer] ?? 0) + e.amount;

      // AA 分摊给谁（默认所有人 AA）
      // 这里 splitMembers 暂时全用所有人 AA，简化第一版
      final splitTo = allMemberIds; // TODO: 后续支持自定义 splitMembers
      final perPerson = e.amount / splitTo.length;
      for (final id in splitTo) {
        owed[id] = (owed[id] ?? 0) + perPerson;
      }
    }

    final balances = allMemberIds.map((id) {
      return MemberBalance(
        id: id,
        name: nameOf[id]!,
        paid: paid[id] ?? 0,
        owed: owed[id] ?? 0,
      );
    }).toList();

    // ============ Step 2: 贪心算法生成最简转账方案 ============
    final transfers = _greedyMinTransfers(balances, nameOf);

    final totalPaid = paid.values.fold(0.0, (a, b) => a + b);

    return SettlementResult(
      balances: balances,
      transfers: transfers,
      totalAmount: totalPaid,
      perPersonAmount: totalPaid / allMemberIds.length,
    );
  }

  /// 贪心算法：最少转账次数让所有人结清
  ///
  /// 算法思路：
  /// 1. 把每人的差额（diff = paid - owed）排序
  /// 2. 找最大债主（diff 最高）和最大欠款人（diff 最低）
  /// 3. 让欠款人转给债主 min(|debt|, credit) 这么多
  /// 4. 重复直到所有人差额接近 0
  ///
  /// 复杂度：O(n²)
  /// 转账次数上界：n-1（实际通常远少于 n-1）
  static List<Transfer> _greedyMinTransfers(
    List<MemberBalance> balances,
    Map<String, String> nameOf,
  ) {
    // 复制差额（要修改，避免污染原数据）
    final diffs = <String, double>{
      for (final b in balances) b.id: b.diff,
    };

    final transfers = <Transfer>[];

    // 浮点容差：差额绝对值 < 0.01 元就认为已结清
    const epsilon = 0.01;

    while (true) {
      // 找最大债主（diff 最大）和最大欠款人（diff 最小）
      String? creditorId;
      String? debtorId;
      double maxCredit = 0;
      double maxDebt = 0;

      diffs.forEach((id, d) {
        if (d > maxCredit) {
          maxCredit = d;
          creditorId = id;
        }
        if (d < -maxDebt) {
          maxDebt = -d;
          debtorId = id;
        }
      });

      // 都已结清
      if (maxCredit < epsilon || maxDebt < epsilon) break;
      if (creditorId == null || debtorId == null) break;

      // 转账金额 = min(欠款额, 应收额)
      final amount = maxCredit < maxDebt ? maxCredit : maxDebt;

      transfers.add(Transfer(
        fromId: debtorId!,
        fromName: nameOf[debtorId!]!,
        toId: creditorId!,
        toName: nameOf[creditorId!]!,
        amount: double.parse(amount.toStringAsFixed(2)),
      ));

      // 更新差额
      diffs[creditorId!] = diffs[creditorId!]! - amount;
      diffs[debtorId!] = diffs[debtorId!]! + amount;
    }

    return transfers;
  }
}

/// 结算结果
class SettlementResult {
  final List<MemberBalance> balances;
  final List<Transfer> transfers;
  final double totalAmount;
  final double perPersonAmount;

  SettlementResult({
    required this.balances,
    required this.transfers,
    required this.totalAmount,
    required this.perPersonAmount,
  });
}