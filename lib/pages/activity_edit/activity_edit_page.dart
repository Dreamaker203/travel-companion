import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/activity_providers.dart';
import '../../models/activity.dart';
import '../../theme/app_theme.dart';

class ActivityEditPage extends ConsumerStatefulWidget {
  final String tripId;
  final int dayNumber;
  final TripActivity? existing;

  const ActivityEditPage({
    super.key,
    required this.tripId,
    required this.dayNumber,
    this.existing,
  });

  @override
  ConsumerState<ActivityEditPage> createState() =>
      _ActivityEditPageState();
}

class _ActivityEditPageState extends ConsumerState<ActivityEditPage> {
  late ActivityType _type;
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _noteController;
  late TextEditingController _costController;
  late TextEditingController _durationController;
  TimeOfDay? _startTime;

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? ActivityType.scenic;
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _costController = TextEditingController(
      text: (e == null || e.estimatedCost == 0)
          ? ''
          : e.estimatedCost.toStringAsFixed(0),
    );
    _durationController = TextEditingController(
      text: e == null ? '60' : e.durationMinutes.toString(),
    );
    if (e != null && e.startTime.isNotEmpty) {
      final parts = e.startTime.split(':');
      if (parts.length == 2) {
        _startTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    _costController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写活动名称')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final timeStr = _startTime == null
          ? ''
          : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}';
      final cost = double.tryParse(_costController.text) ?? 0;
      final duration = int.tryParse(_durationController.text) ?? 60;

      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          type: _type,
          title: _titleController.text.trim(),
          location: _locationController.text.trim(),
          note: _noteController.text.trim(),
          estimatedCost: cost,
          durationMinutes: duration,
          startTime: timeStr,
        );
       await ref
      .read(activityListProvider(widget.tripId).notifier)
      .updateActivity(updated); 
      } else {
        await ref.read(activityListProvider(widget.tripId).notifier).createActivity(
              dayNumber: widget.dayNumber,
              title: _titleController.text.trim(),
              type: _type,
              location: _locationController.text.trim(),
              note: _noteController.text.trim(),
              estimatedCost: cost,
              durationMinutes: duration,
              startTime: timeStr,
              orderIndex: DateTime.now().millisecondsSinceEpoch,
            );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除活动'),
        content: const Text('确定要删除这个活动吗？'),
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
      await ref
      .read(activityListProvider(widget.tripId).notifier)
      .deleteActivity(widget.existing!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? '编辑活动' : '添加活动',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('保存', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLabel('活动类型'),
          _buildTypeSelector(),
          const SizedBox(height: 18),
          _buildLabel('名称'),
          _buildTextField(
            controller: _titleController,
            hint: '例如：故宫博物院',
          ),
          const SizedBox(height: 18),
          _buildLabel('地点'),
          _buildTextField(
            controller: _locationController,
            hint: '例如：景山前街 4 号',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('开始时间'),
                    _buildTimeField(),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('时长（分钟）'),
                    _buildTextField(
                      controller: _durationController,
                      hint: '60',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('费用 ¥'),
                    _buildTextField(
                      controller: _costController,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildLabel('备注'),
          _buildTextField(
            controller: _noteController,
            hint: '例如：建议提前购票',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [
      ActivityType.scenic,
      ActivityType.diningBreakfast,
      ActivityType.diningMain,
      ActivityType.transport,
      ActivityType.lodging,
      ActivityType.shopping,
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: types.map((t) {
        final selected = t == _type;
        return GestureDetector(
          onTap: () => setState(() => _type = t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? t.color.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? t.color : AppTheme.border,
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.icon, size: 14, color: selected ? t.color : AppTheme.textSecondary),
                const SizedBox(width: 5),
                Text(
                  t.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? t.color : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1),
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: _pickStartTime,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _startTime == null
                  ? '选择时间'
                  : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 13,
                color: _startTime == null
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
              ),
            ),
            const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}