import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ============= 旅行表 =============
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get destination => text().withDefault(const Constant(''))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  RealColumn get totalBudget => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  TextColumn get status => text().withDefault(const Constant('planning'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============= 活动表 =============
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id)();
  IntColumn get dayNumber => integer()();
  TextColumn get type => text().withDefault(const Constant('scenic'))();
  TextColumn get title => text()();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get startTime => text().withDefault(const Constant(''))();
  IntColumn get durationMinutes => integer().withDefault(const Constant(60))();
  RealColumn get estimatedCost => real().withDefault(const Constant(0))();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============= 支出表 =============
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id)();
  TextColumn get activityId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  // 新加的三个字段：
  TextColumn get paidBy => text().withDefault(const Constant('self'))();
  TextColumn get splitMethod => text().withDefault(const Constant('aa'))();
  TextColumn get splitMembers => text().withDefault(const Constant('[]'))(); // JSON
  // 原来的字段：
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get occurredAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============= 同行者表 =============
class Companions extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id)();
  TextColumn get name => text()();
  IntColumn get avatarColor => integer().withDefault(const Constant(0xFF534AB7))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============= 数据库类 =============
@DriftDatabase(tables: [Trips, Activities, Expenses, Companions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(expenses);
          }
          if (from < 3) {
            await migrator.createTable(companions);
            // 给 expenses 表加新字段
            await migrator.addColumn(expenses, expenses.paidBy);
            await migrator.addColumn(expenses, expenses.splitMethod);
            await migrator.addColumn(expenses, expenses.splitMembers);
          }
        },
    );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'travel_companion');
  }
}