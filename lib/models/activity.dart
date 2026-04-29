import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ActivityType {
  scenic,        // 景点
  diningBreakfast, // 早餐
  diningMain,    // 正餐
  transport,     // 交通
  lodging,       // 住宿
  shopping,      // 购物
  free,          // 自由
}

extension ActivityTypeExt on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.scenic:
        return '景点';
      case ActivityType.diningBreakfast:
        return '早餐';
      case ActivityType.diningMain:
        return '餐饮';
      case ActivityType.transport:
        return '交通';
      case ActivityType.lodging:
        return '住宿';
      case ActivityType.shopping:
        return '购物';
      case ActivityType.free:
        return '自由';
    }
  }

  Color get color {
    switch (this) {
      case ActivityType.scenic:
        return AppTheme.scenic;
      case ActivityType.diningBreakfast:
        return AppTheme.diningBreakfast;
      case ActivityType.diningMain:
        return AppTheme.diningMain;
      case ActivityType.transport:
        return AppTheme.transport;
      case ActivityType.lodging:
        return AppTheme.lodging;
      case ActivityType.shopping:
        return AppTheme.shopping;
      case ActivityType.free:
        return AppTheme.textSecondary;
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityType.scenic:
        return Icons.location_on_outlined;
      case ActivityType.diningBreakfast:
      case ActivityType.diningMain:
        return Icons.restaurant_outlined;
      case ActivityType.transport:
        return Icons.directions_walk;
      case ActivityType.lodging:
        return Icons.hotel_outlined;
      case ActivityType.shopping:
        return Icons.shopping_bag_outlined;
      case ActivityType.free:
        return Icons.access_time;
    }
  }
}

class TripActivity {
  final String id;
  final String tripId;
  final int dayNumber;
  final ActivityType type;
  final String title;
  final String location;
  final String startTime;
  final int durationMinutes;
  final double estimatedCost;
  final String note;
  final int orderIndex;
  final DateTime createdAt;

  TripActivity({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    this.type = ActivityType.scenic,
    required this.title,
    this.location = '',
    this.startTime = '',
    this.durationMinutes = 60,
    this.estimatedCost = 0,
    this.note = '',
    this.orderIndex = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TripActivity copyWith({
    int? dayNumber,
    ActivityType? type,
    String? title,
    String? location,
    String? startTime,
    int? durationMinutes,
    double? estimatedCost,
    String? note,
    int? orderIndex,
  }) {
    return TripActivity(
      id: id,
      tripId: tripId,
      dayNumber: dayNumber ?? this.dayNumber,
      type: type ?? this.type,
      title: title ?? this.title,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      note: note ?? this.note,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt,
    );
  }
}