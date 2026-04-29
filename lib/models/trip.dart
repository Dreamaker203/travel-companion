class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double totalBudget;
  final String currency;
  final String status;
  final DateTime createdAt;

  Trip({
    required this.id,
    required this.title,
    this.destination = '',
    required this.startDate,
    required this.endDate,
    this.totalBudget = 0,
    this.currency = 'CNY',
    this.status = 'planning',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 总天数
  int get totalDays => endDate.difference(startDate).inDays + 1;

  // 状态显示文字
  String get statusLabel {
    switch (status) {
      case 'planning':
        return '规划中';
      case 'ongoing':
        return '进行中';
      case 'completed':
        return '已完成';
      default:
        return status;
    }
  }

  Trip copyWith({
    String? title,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    double? totalBudget,
    String? currency,
    String? status,
  }) {
    return Trip(
      id: id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalBudget: totalBudget ?? this.totalBudget,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}