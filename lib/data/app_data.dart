import 'database/database.dart';
import 'repositories/trip_repository.dart';
import 'repositories/activity_repository.dart';

/// 全局数据访问入口
class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  late final AppDatabase database;
  late final TripRepository tripRepo;
  late final ActivityRepository activityRepo;

  void init() {
    database = AppDatabase();
    tripRepo = TripRepository(database);
    activityRepo = ActivityRepository(database);
  }
}