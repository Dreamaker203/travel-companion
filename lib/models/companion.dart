import 'package:flutter/material.dart';

/// 同行者
/// 名字叫 TripCompanion 是为了避开 Drift 自己的 "Companion" 概念
class TripCompanion {
  final String id;
  final String tripId;
  final String name;
  final int avatarColor; // ARGB int

  TripCompanion({
    required this.id,
    required this.tripId,
    required this.name,
    int? avatarColor,
  }) : avatarColor = avatarColor ?? 0xFF534AB7;

  Color get color => Color(avatarColor);

  /// 头像首字母（最多 2 个字符）
  String get initials {
    if (name.isEmpty) return '?';
    if (name.length <= 2) return name;
    // 中文取头两字，英文取首字母
    final isChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(name);
    if (isChinese) return name.substring(0, 1);
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  TripCompanion copyWith({String? name, int? avatarColor}) {
    return TripCompanion(
      id: id,
      tripId: tripId,
      name: name ?? this.name,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}

/// 同行者头像可选颜色（用户切换时用的预设）
const List<int> kAvatarColors = [
  0xFF534AB7, // 紫
  0xFF1D9E75, // 绿
  0xFFEF9F27, // 橙
  0xFFD4537E, // 粉
  0xFF185FA5, // 蓝
  0xFF993C1D, // 红棕
];