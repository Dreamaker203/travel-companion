import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_data.dart';
import '../data/repositories/activity_repository.dart';
import '../models/activity.dart';

// ============= Repository Provider =============
final activityRepoProvider = Provider<ActivityRepository>((ref) {
  return AppData().activityRepo;
});

// ============= 活动列表（按 tripId 参数化） =============
class ActivityListNotifier
    extends FamilyAsyncNotifier<List<TripActivity>, String> {
  @override
  Future<List<TripActivity>> build(String tripId) async {
    final repo = ref.read(activityRepoProvider);
    return repo.getActivitiesByTrip(tripId);
  }

  Future<TripActivity> createActivity({
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
    final repo = ref.read(activityRepoProvider);
    final activity = await repo.createActivity(
      tripId: arg,
      dayNumber: dayNumber,
      title: title,
      type: type,
      location: location,
      startTime: startTime,
      durationMinutes: durationMinutes,
      estimatedCost: estimatedCost,
      note: note,
      orderIndex: orderIndex,
    );
    ref.invalidateSelf();
    return activity;
  }

  Future<void> updateActivity(TripActivity activity) async {
    final repo = ref.read(activityRepoProvider);
    await repo.updateActivity(activity);
    ref.invalidateSelf();
  }

  Future<void> deleteActivity(String id) async {
    final repo = ref.read(activityRepoProvider);
    await repo.deleteActivity(id);
    ref.invalidateSelf();
  }

    // 移动活动到另一天（或待定池 dayNumber=0）
  Future<void> moveActivityToDay(String activityId, int newDayNumber) async {
    final repo = ref.read(activityRepoProvider);
    await repo.moveActivityToDay(activityId, newDayNumber);
    ref.invalidateSelf();
  }
}

// 关键变化在这里：family 的写法
final activityListProvider =
    AsyncNotifierProviderFamily<ActivityListNotifier, List<TripActivity>, String>(
  ActivityListNotifier.new,
);