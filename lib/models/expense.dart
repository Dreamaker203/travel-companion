import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ExpenseCategory {
  scenic,    // 景点门票
  dining,    // 餐饮
  transport, // 交通
  lodging,   // 住宿
  shopping,  // 购物
  other,     // 其他
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
    this.note = '',
    DateTime? occurredAt,
    DateTime? createdAt,
  })  : occurredAt = occurredAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Expense copyWith({
    double? amount,
    String? currency,
    ExpenseCategory? category,
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
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt,
    );
  }
}