import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/activity.dart';
import '../../models/trip.dart';
import '../../providers/activity_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/pdf_exporter.dart';
import '../../widgets/activity_tile.dart';
import '../activity_edit/activity_edit_page.dart';

class TripDetailPage extends ConsumerStatefulWidget {
  final Trip trip;
  const TripDetailPage({super.key, required this.trip});

  @override
  ConsumerState<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends ConsumerState<TripDetailPage> {
  int _selectedDay = 1;

  int get _totalDays => widget.trip.totalDays;

  Future<void> _onAddActivity() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityEditPage(
          tripId: widget.trip.id,
          dayNumber: _selectedDay,
        ),
      ),
    );
    // 不需要手动刷新——activityListProvider 自动同步
  }

  Future<void> _onEditActivity(TripActivity act) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityEditPage(
          tripId: widget.trip.id,
          dayNumber: act.dayNumber,
          existing: act,
        ),
      ),
    );
  }

  Future<void> _onExportPdf(List<TripActivity> activities) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在生成 PDF...'),
        duration: Duration(seconds: 1),
      ),
    );
    try {
      await PdfExporter.exportTripDetailed(
        trip: widget.trip,
        activities: activities,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('M/d');
    final headerDateFmt = DateFormat('yyyy.M.d');

    final activitiesAsync =
        ref.watch(activityListProvider(widget.trip.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.trip.title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              '${headerDateFmt.format(widget.trip.startDate)} – ${headerDateFmt.format(widget.trip.endDate)}'
              '${widget.trip.totalBudget > 0 ? ' · 预算 ¥ ${widget.trip.totalBudget.toStringAsFixed(0)}' : ''}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        toolbarHeight: 64,
        actions: [
          IconButton(
            onPressed: () {
              activitiesAsync.whenData((list) => _onExportPdf(list));
            },
            icon: const Icon(Icons.ios_share, size: 20),
            tooltip: '导出 PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDayTabs(dateFmt),
          activitiesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(''),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(''),
            ),
            data: (all) {
              final today = all
                  .where((a) => a.dayNumber == _selectedDay)
                  .toList();
              final todayCost =
                  today.fold(0.0, (sum, a) => sum + a.estimatedCost);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${today.length} 个活动',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (todayCost > 0)
                      Text(
                        '当日 ¥ ${todayCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: activitiesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('加载失败：$e',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (all) {
                final today = all
                    .where((a) => a.dayNumber == _selectedDay)
                    .toList();
                if (today.isEmpty) return _buildEmpty();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: today.length,
                  itemBuilder: (ctx, i) {
                    final act = today[i];
                    return ActivityTile(
                      activity: act,
                      onTap: () => _onEditActivity(act),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddActivity,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDayTabs(DateFormat dateFmt) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(_totalDays, (i) {
          final dayNum = i + 1;
          final selected = dayNum == _selectedDay;
          final date = widget.trip.startDate.add(Duration(days: i));
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDay = dayNum),
              child: Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'D$dayNum',
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dateFmt.format(date),
                      style: TextStyle(
                        fontSize: 9,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 56,
              color: AppTheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'D$_selectedDay 还没有安排',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '点击右下角 + 添加第一个活动',
              style: TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}