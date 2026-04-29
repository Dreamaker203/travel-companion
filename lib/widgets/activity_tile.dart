import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../theme/app_theme.dart';

class ActivityTile extends StatelessWidget {
  final TripActivity activity;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const ActivityTile({
    super.key,
    required this.activity,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = activity.type.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 左侧：时间 + 圆点
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  activity.startTime.isEmpty ? '--:--' : activity.startTime,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // 中间：圆点 + 竖线
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    color: AppTheme.border,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // 右侧：活动卡片
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 第一行：类型 + 时长 + 费用
                        Row(
                          children: [
                            Icon(activity.type.icon, size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              activity.type.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (activity.durationMinutes > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '· ${_formatDuration(activity.durationMinutes)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                            const Spacer(),
                            if (activity.estimatedCost > 0)
                              Text(
                                '¥ ${activity.estimatedCost.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 标题
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // 地点（可选）
                        if (activity.location.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            activity.location,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        // 备注（可选）
                        if (activity.note.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            activity.note,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ?trailing,
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes 分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h 小时';
    return '$h 小时 $m 分';
  }
}