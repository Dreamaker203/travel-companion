import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart' as db;
import '../../models/activity.dart';

class ActivityRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  ActivityRepository(this._db);

  // 查询某次旅行的所有活动（按天 + 顺序）
  Future<List<TripActivity>> getActivitiesByTrip(String tripId) async {
    final query = _db.select(_db.activities)
      ..where((a) => a.tripId.equals(tripId))
      ..orderBy([
        (a) => OrderingTerm.asc(a.dayNumber),
        (a) => OrderingTerm.asc(a.orderIndex),
      ]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  // 查询某次旅行某一天的活动
  Future<List<TripActivity>> getActivitiesByDay(String tripId, int dayNumber) async {
    final query = _db.select(_db.activities)
      ..where((a) => a.tripId.equals(tripId) & a.dayNumber.equals(dayNumber))
      ..orderBy([(a) => OrderingTerm.asc(a.orderIndex)]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  // 新建活动
  Future<TripActivity> createActivity({
    required String tripId,
    required int dayNumber,
    required String title,
    ActivityType type = ActivityType.scenic,
    String location = '',
    String startTime = '',
    int durationMinutes = 60,
    double estimatedCost = 0,
    String note = '',
    int orderIndex = 0,
  }) async {
    final id = _uuid.v4();
    final companion = db.ActivitiesCompanion.insert(
      id: id,
      tripId: tripId,
      dayNumber: dayNumber,
      title: title,
      type: Value(type.name),
      location: Value(location),
      startTime: Value(startTime),
      durationMinutes: Value(durationMinutes),
      estimatedCost: Value(estimatedCost),
      note: Value(note),
      orderIndex: Value(orderIndex),
    );
    await _db.into(_db.activities).insert(companion);
    final row = await (_db.select(_db.activities)..where((a) => a.id.equals(id)))
        .getSingle();
    return _toModel(row);
  }

  // 更新
  Future<void> updateActivity(TripActivity activity) async {
    await (_db.update(_db.activities)..where((a) => a.id.equals(activity.id)))
        .write(
      db.ActivitiesCompanion(
        dayNumber: Value(activity.dayNumber),
        type: Value(activity.type.name),
        title: Value(activity.title),
        location: Value(activity.location),
        startTime: Value(activity.startTime),
        durationMinutes: Value(activity.durationMinutes),
        estimatedCost: Value(activity.estimatedCost),
        note: Value(activity.note),
        orderIndex: Value(activity.orderIndex),
      ),
    );
  }

  // 删除
  Future<void> deleteActivity(String id) async {
    await (_db.delete(_db.activities)..where((a) => a.id.equals(id))).go();
  }

  TripActivity _toModel(db.Activity row) {
    return TripActivity(
      id: row.id,
      tripId: row.tripId,
      dayNumber: row.dayNumber,
      type: ActivityType.values.firstWhere(
        (e) => e.name == row.type,
        orElse: () => ActivityType.scenic,
      ),
      title: row.title,
      location: row.location,
      startTime: row.startTime,
      durationMinutes: row.durationMinutes,
      estimatedCost: row.estimatedCost,
      note: row.note,
      orderIndex: row.orderIndex,
      createdAt: row.createdAt,
    );
  }
}