import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'data/app_data.dart';
import 'pages/trip_list/trip_list_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化中文日期格式
  initializeDateFormattingForChinese();
  AppData().init();
  runApp(const ProviderScope(child: TravelCompanionApp()));
}

void initializeDateFormattingForChinese() {
  initializeDateFormatting('zh_CN', null);
}

class TravelCompanionApp extends StatelessWidget {
  const TravelCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '旅行伴侣',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // 中文日期选择器需要
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const TripListPage(),
    );
  }
}