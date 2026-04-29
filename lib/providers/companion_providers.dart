import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_data.dart';
import '../data/repositories/companion_repository.dart';
import '../models/companion.dart';

final companionRepoProvider = Provider<CompanionRepository>((ref) {
  return AppData().companionRepo;
});

class CompanionListNotifier
    extends FamilyAsyncNotifier<List<TripCompanion>, String> {
  @override
  Future<List<TripCompanion>> build(String tripId) async {
    final repo = ref.read(companionRepoProvider);
    return repo.getCompanionsByTrip(tripId);
  }

  Future<TripCompanion> createCompanion({
    required String name,
    int? avatarColor,
  }) async {
    final repo = ref.read(companionRepoProvider);
    final c = await repo.createCompanion(
      tripId: arg,
      name: name,
      avatarColor: avatarColor,
    );
    ref.invalidateSelf();
    return c;
  }

  Future<void> updateCompanion(TripCompanion c) async {
    final repo = ref.read(companionRepoProvider);
    await repo.updateCompanion(c);
    ref.invalidateSelf();
  }

  Future<void> deleteCompanion(String id) async {
    final repo = ref.read(companionRepoProvider);
    await repo.deleteCompanion(id);
    ref.invalidateSelf();
  }
}

final companionListProvider = AsyncNotifierProvider.family<CompanionListNotifier, List<TripCompanion>, String>(
  CompanionListNotifier.new,
);