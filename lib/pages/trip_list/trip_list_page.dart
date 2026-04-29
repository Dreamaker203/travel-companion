import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip.dart';
import '../../providers/trip_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/trip_card.dart';
import '../trip_create/trip_create_page.dart';
import '../trip_detail/trip_detail_page.dart';

class TripListPage extends ConsumerWidget {
  const TripListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripListProvider);
    final filter = ref.watch(tripFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '你好，Dreamaker',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '我的旅行',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 76,
      ),
      body: Column(
        children: [
          _FilterTabs(currentFilter: filter),
          const SizedBox(height: 4),
          Expanded(
            child: tripsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    '加载失败：$e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
              data: (trips) =>
                  trips.isEmpty ? const _Empty() : _TripList(trips: trips),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TripCreatePage()),
          );
          // 不需要手动刷新——Provider 会自动同步
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ============= 子组件：筛选标签 =============
class _FilterTabs extends ConsumerWidget {
  final String currentFilter;
  const _FilterTabs({required this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = [
      ('all', '全部'),
      ('planning', '规划中'),
      ('ongoing', '进行中'),
      ('completed', '已完成'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final selected = f.$1 == currentFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () =>
                  ref.read(tripFilterProvider.notifier).setFilter(f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppTheme.primary : AppTheme.border,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ============= 子组件：旅行列表 =============
class _TripList extends ConsumerWidget {
  final List<Trip> trips;
  const _TripList({required this.trips});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: trips.length,
      itemBuilder: (ctx, i) {
        final trip = trips[i];
        return TripCard(
          trip: trip,
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => TripDetailPage(trip: trip)),
          ),
          onLongPress: () => _confirmDelete(ctx, ref, trip),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除旅行'),
        content: Text('确定要删除"${trip.title}"吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(tripListProvider.notifier).deleteTrip(trip.id);
    }
  }
}

// ============= 子组件：空状态 =============
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 64,
              color: AppTheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              '还没有旅行',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '点击右下角 + 创建你的第一次旅行',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}