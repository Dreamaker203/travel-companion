import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/database.dart' as db;
import '../../models/companion.dart';

class CompanionRepository {
  final db.AppDatabase _db;
  final _uuid = const Uuid();

  CompanionRepository(this._db);

  Future<List<TripCompanion>> getCompanionsByTrip(String tripId) async {
    final query = _db.select(_db.companions)
      ..where((c) => c.tripId.equals(tripId))
      ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]);
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  Future<TripCompanion> createCompanion({
    required String tripId,
    required String name,
    int? avatarColor,
  }) async {
    final id = _uuid.v4();
    final companion = db.CompanionsCompanion.insert(
      id: id,
      tripId: tripId,
      name: name,
      avatarColor: Value(avatarColor ?? 0xFF534AB7),
    );
    await _db.into(_db.companions).insert(companion);
    final row = await (_db.select(_db.companions)..where((c) => c.id.equals(id)))
        .getSingle();
    return _toModel(row);
  }

  Future<void> updateCompanion(TripCompanion c) async {
    await (_db.update(_db.companions)..where((row) => row.id.equals(c.id)))
        .write(db.CompanionsCompanion(
      name: Value(c.name),
      avatarColor: Value(c.avatarColor),
    ));
  }

  Future<void> deleteCompanion(String id) async {
    await (_db.delete(_db.companions)..where((c) => c.id.equals(id))).go();
  }

  TripCompanion _toModel(db.Companion row) {
    return TripCompanion(
      id: row.id,
      tripId: row.tripId,
      name: row.name,
      avatarColor: row.avatarColor,
    );
  }
}