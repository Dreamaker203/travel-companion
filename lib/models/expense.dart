import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ExpenseCategory {
  scenic,
  dining,
  transport,
  lodging,
  shopping,
  other,
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.scenic:
        return '景点门票';
      case ExpenseCategory.dining:
        return '餐饮';
      case ExpenseCategory.transport:
        return '交通';
      case ExpenseCategory.lodging:
        return '住宿';
      case ExpenseCategory.shopping:
        return '购物';
      case ExpenseCategory.other:
        return '其他';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.scenic:
        return AppTheme.scenic;
      case ExpenseCategory.dining:
        return AppTheme.diningMain;
      case ExpenseCategory.transport:
        return AppTheme.transport;
      case ExpenseCategory.lodging:
        return AppTheme.lodging;
      case ExpenseCategory.shopping:
        return AppTheme.shopping;
      case ExpenseCategory.other:
        return AppTheme.textSecondary;
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.scenic:
        return Icons.location_on_outlined;
      case ExpenseCategory.dining:
        return Icons.restaurant_outlined;
      case ExpenseCategory.transport:
        return Icons.directions_walk;
      case ExpenseCategory.lodging:
        return Icons.hotel_outlined;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}

class Expense {
  final String id;
  final String tripId;
  final String? activityId;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  // 新增三个字段：
  final String paidBy;          // 谁付的：'self' 或 companionId
  final String splitMethod;     // 'aa' = 平摊；'single' = 单人承担
  final List<String> splitMembers; // 参与分摊的成员 ID（空表示全员）
  final String note;
  final DateTime occurredAt;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.tripId,
    this.activityId,
    required this.amount,
    this.currency = 'CNY',
    this.category = ExpenseCategory.other,
    this.paidBy = 'self',
    this.splitMethod = 'aa',
    this.splitMembers = const [],
    this.note = '',
    DateTime? occurredAt,
    DateTime? createdAt,
  })  : occurredAt = occurredAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Expense copyWith({
    double? amount,
    String? currency,
    ExpenseCategory? category,
    String? paidBy,
    String? splitMethod,
    List<String>? splitMembers,
    String? note,
    DateTime? occurredAt,
  }) {
    return Expense(
      id: id,
      tripId: tripId,
      activityId: activityId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      paidBy: paidBy ?? this.paidBy,
      splitMethod: splitMethod ?? this.splitMethod,
      splitMembers: splitMembers ?? this.splitMembers,
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt,
    );
  }
}