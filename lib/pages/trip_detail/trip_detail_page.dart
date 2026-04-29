import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/app_data.dart';
import '../../models/activity.dart';
import '../../models/trip.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_tile.dart';
import '../activity_edit/activity_edit_page.dart';
import '../../utils/pdf_exporter.dart';

class TripDetailPage extends StatefulWidget {
  final Trip trip;
  const TripDetailPage({super.key, required this.trip});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  int _selectedDay = 1;
  List<TripActivity> _allActivities = [];
  bool _loading = true;

  int get _totalDays => widget.trip.totalDays;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _loading = true);
    final list =
        await AppData().activityRepo.getActivitiesByTrip(widget.trip.id);
    if (mounted) {
      setState(() {
        _allActivities = list;
        _loading = false;
      });
    }
  }

  List<TripActivity> get _todayActivities =>
      _allActivities.where((a) => a.dayNumber == _selectedDay).toList();

  double get _todayCost =>
      _todayActivities.fold(0, (sum, a) => sum + a.estimatedCost);

  Future<void> _onAddActivity() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityEditPage(
          tripId: widget.trip.id,
          dayNumber: _selectedDay,
        ),
      ),
    );
    if (created == true) _loadActivities();
  }

  Future<void> _onEditActivity(TripActivity act) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityEditPage(
          tripId: widget.trip.id,
          dayNumber: act.dayNumber,
          existing: act,
        ),
      ),
    );
    if (updated == true) _loadActivities();
  }
  Future<void> _onExportPdf() async {
    if (_loading) return;
    
    // 提示用户正在生成
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在生成 PDF...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    try {
      await PdfExporter.exportTripDetailed(
        trip: widget.trip,
        activities: _allActivities,
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

    return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.trip.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
              onPressed: _onExportPdf,
              icon: const Icon(Icons.ios_share, size: 20),
              tooltip: '导出 PDF',
            ),
          ],
        ),
      body: Column(
        children: [
          _buildDayTabs(dateFmt),
          _buildSummaryBar(),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(child: _buildContent()),
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

  Widget _buildSummaryBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_todayActivities.length} 个活动',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          if (_todayCost > 0)
            Text(
              '当日 ¥ ${_todayCost.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_todayActivities.isEmpty) {
      return _buildEmpty();
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _todayActivities.length,
      itemBuilder: (ctx, i) {
        final act = _todayActivities[i];
        return ActivityTile(
          activity: act,
          onTap: () => _onEditActivity(act),
        );
      },
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
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}