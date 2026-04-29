import 'package:flutter/material.dart';

class AppTheme {
  // 品牌色（来自我们的设计系统）
  static const Color primary = Color(0xFF26215C);      // 深紫
  static const Color primaryLight = Color(0xFF534AB7); // 辅紫
  static const Color primaryBg = Color(0xFFEEEDFE);    // 浅紫强调背景

  // 活动类型颜色
  static const Color scenic = Color(0xFF534AB7);      // 景点
  static const Color diningBreakfast = Color(0xFFEF9F27); // 早餐黄
  static const Color diningMain = Color(0xFF1D9E75);  // 正餐绿
  static const Color transport = Color(0xFF888780);   // 交通灰
  static const Color lodging = Color(0xFF185FA5);     // 住宿蓝
  static const Color shopping = Color(0xFFD4537E);    // 购物粉

  // 中性色
  static const Color background = Color(0xFFF7F5EF);  // 米色背景
  static const Color textPrimary = Color(0xFF1C1B19);
  static const Color textSecondary = Color(0xFF5F5E5A);
  static const Color border = Color(0xFFD3D1C7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryLight,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      fontFamily: 'NotoSansSC', // 中文字体，支持全平台
    );
  }
}