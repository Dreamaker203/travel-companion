import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../theme/app_theme.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M月d日');
    final dateRange =
        '${dateFormat.format(trip.startDate)} – ${dateFormat.format(trip.endDate)}';

    // 状态对应的徽章颜色
    final (Color badgeBg, Color badgeText) = switch (trip.status) {
      'ongoing' => (AppTheme.primary, Colors.white),
      'planning' => (const Color(0xFFE1F5EE), const Color(0xFF0F6E56)),
      'completed' => (const Color(0xFFF1EFE8), const Color(0xFF5F5E5A)),
      _ => (AppTheme.primaryBg, AppTheme.primary),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 封面区（用渐变色块代替真实图片）
              _buildCover(badgeBg, badgeText),
              // 内容区
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$dateRange · ${trip.totalDays} 天',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (trip.totalBudget > 0)
                          Text(
                            '${_currencySymbol(trip.currency)} ${trip.totalBudget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover(Color badgeBg, Color badgeText) {
    // 不同状态用不同颜色块代表封面
    final (Color top, Color bottom) = switch (trip.status) {
      'ongoing' => (AppTheme.primaryBg, const Color(0xFFCECBF6)),
      'planning' => (const Color(0xFFE1F5EE), const Color(0xFF9FE1CB)),
      'completed' => (const Color(0xFFF1EFE8), const Color(0xFFD3D1C7)),
      _ => (AppTheme.primaryBg, const Color(0xFFCECBF6)),
    };

    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trip.statusLabel,
              style: TextStyle(
                fontSize: 10,
                color: badgeText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _currencySymbol(String code) {
    return switch (code) {
      'CNY' => '¥',
      'USD' => '\$',
      'EUR' => '€',
      'JPY' => '¥',
      _ => code,
    };
  }
}