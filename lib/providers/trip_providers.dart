import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_data.dart';
import '../data/repositories/trip_repository.dart';
import '../models/trip.dart';

// ============= Repository Provider =============
// 把 Repository 暴露成 Provider，便于其他 Provider 引用
final tripRepoProvider = Provider<TripRepository>((ref) {
  return AppData().tripRepo;
});

// ============= 当前筛选状态 =============
class TripFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String value) {
    state = value;
  }
}

final tripFilterProvider =
    NotifierProvider<TripFilterNotifier, String>(TripFilterNotifier.new);

// ============= 旅行列表（核心） =============
class TripListNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    final filter = ref.watch(tripFilterProvider);
    final repo = ref.read(tripRepoProvider);
    return filter == 'all'
        ? repo.getAllTrips()
        : repo.getTripsByStatus(filter);
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
    final repo = ref.read(tripRepoProvider);
    final trip = await repo.createTrip(
      title: title,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      totalBudget: totalBudget,
      currency: currency,
    );
    // 触发列表自动刷新
    ref.invalidateSelf();
    return trip;
  }

  // 更新旅行
  Future<void> updateTrip(Trip trip) async {
    final repo = ref.read(tripRepoProvider);
    await repo.updateTrip(trip);
    ref.invalidateSelf();
  }

  // 删除旅行
  Future<void> deleteTrip(String id) async {
    final repo = ref.read(tripRepoProvider);
    await repo.deleteTrip(id);
    ref.invalidateSelf();
  }
}

final tripListProvider =
    AsyncNotifierProvider<TripListNotifier, List<Trip>>(TripListNotifier.new);