import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart' as db;
import '../../models/trip.dart';

class TripRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  TripRepository(this._db);

  // 查询所有旅行（按创建时间倒序）
  Future<List<Trip>> getAllTrips() async {
    final query = _db.select(_db.trips)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  // 按状态查询
  Future<List<Trip>> getTripsByStatus(String status) async {
    final query = _db.select(_db.trips)
      ..where((t) => t.status.equals(status))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  // 按 ID 查询单个
  Future<Trip?> getTripById(String id) async {
    final row = await (_db.select(_db.trips)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  // 新建旅行
  Future<Trip> createTrip({
    required String title,
    String destination = '',
    required DateTime startDate,
    required DateTime endDate,
    double totalBudget = 0,
    String currency = 'CNY',
  }) async {
    final id = _uuid.v4();
    final companion = db.TripsCompanion.insert(
      id: id,
      title: title,
      destination: Value(destination),
      startDate: startDate,
      endDate: endDate,
      totalBudget: Value(totalBudget),
      currency: Value(currency),
    );
    await _db.into(_db.trips).insert(companion);
    return (await getTripById(id))!;
  }

  // 更新
  Future<void> updateTrip(Trip trip) async {
    await (_db.update(_db.trips)..where((t) => t.id.equals(trip.id))).write(
      db.TripsCompanion(
        title: Value(trip.title),
        destination: Value(trip.destination),
        startDate: Value(trip.startDate),
        endDate: Value(trip.endDate),
        totalBudget: Value(trip.totalBudget),
        currency: Value(trip.currency),
        status: Value(trip.status),
      ),
    );
  }

  // 删除
  Future<void> deleteTrip(String id) async {
    await (_db.delete(_db.trips)..where((t) => t.id.equals(id))).go();
  }

  // 数据库行 → 业务模型
  Trip _toModel(db.Trip row) {
    return Trip(
      id: row.id,
      title: row.title,
      destination: row.destination,
      startDate: row.startDate,
      endDate: row.endDate,
      totalBudget: row.totalBudget,
      currency: row.currency,
      status: row.status,
      createdAt: row.createdAt,
    );
  }
}