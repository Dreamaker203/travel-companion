import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/companion.dart';
import '../../providers/companion_providers.dart';
import '../../theme/app_theme.dart';

class CompanionsPage extends ConsumerWidget {
  final String tripId;
  const CompanionsPage({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionsAsync = ref.watch(companionListProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '同行者',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
      ),
      body: companionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (companions) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 组织者卡片（永远显示）
              _buildSelfCard(),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '同行者',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...companions.map((c) => _buildCompanionCard(context, ref, c)),
              if (companions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    '还没有同行者，点击右下角 + 添加',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildSelfCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary,
            child: const Text(
              '我',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '我',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '组织者',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'YOU',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionCard(
      BuildContext context, WidgetRef ref, TripCompanion c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: c.color,
            child: Text(
              c.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              c.name,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red,
            onPressed: () => _confirmDelete(context, ref, c),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    int selectedColor = kAvatarColors.first;

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('添加同行者'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '姓名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '头像颜色',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: kAvatarColors.map((c) {
                  final selected = c == selectedColor;
                  return GestureDetector(
                    onTap: () =>
                        setStateDialog(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppTheme.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (added == true && controller.text.trim().isNotEmpty) {
      await ref
          .read(companionListProvider(tripId).notifier)
          .createCompanion(
            name: controller.text.trim(),
            avatarColor: selectedColor,
          );
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, TripCompanion c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除同行者'),
        content: Text('确定要删除"${c.name}"吗？'),
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
          .read(companionListProvider(tripId).notifier)
          .deleteCompanion(c.id);
    }
  }
}