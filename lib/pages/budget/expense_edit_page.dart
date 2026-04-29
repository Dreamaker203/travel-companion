import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/expense.dart';
import '../../providers/expense_providers.dart';
import '../../theme/app_theme.dart';

class ExpenseEditPage extends ConsumerStatefulWidget {
  final String tripId;
  final Expense? existing;

  const ExpenseEditPage({
    super.key,
    required this.tripId,
    this.existing,
  });

  @override
  ConsumerState<ExpenseEditPage> createState() => _ExpenseEditPageState();
}

class _ExpenseEditPageState extends ConsumerState<ExpenseEditPage> {
  late ExpenseCategory _category;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.category ?? ExpenseCategory.dining;
    _amountController = TextEditingController(
      text: e == null ? '' : e.amount.toStringAsFixed(0),
    );
    _noteController = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写有效金额')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        final updated = widget.existing!.copyWith(
          amount: amount,
          category: _category,
          note: _noteController.text.trim(),
        );
        await ref
            .read(expenseListProvider(widget.tripId).notifier)
            .updateExpense(updated);
      } else {
        await ref
            .read(expenseListProvider(widget.tripId).notifier)
            .createExpense(
              amount: amount,
              category: _category,
              note: _noteController.text.trim(),
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
        title: const Text('删除这笔支出'),
        content: const Text('确定要删除这笔支出吗？'),
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
          .read(expenseListProvider(widget.tripId).notifier)
          .deleteExpense(widget.existing!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? '编辑支出' : '记一笔',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
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
        padding: const EdgeInsets.all(20),
        children: [
          _buildLabel('金额'),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: AppTheme.primary,
            ),
            decoration: InputDecoration(
              prefixText: '¥ ',
              prefixStyle: const TextStyle(
                fontSize: 24,
                color: AppTheme.primary,
              ),
              hintText: '0',
              hintStyle: const TextStyle(
                fontSize: 32,
                color: AppTheme.textSecondary,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppTheme.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _buildLabel('类别'),
          _buildCategorySelector(),
          const SizedBox(height: 22),
          _buildLabel('备注（可选）'),
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: '例如：四季民福午餐',
              hintStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppTheme.border, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppTheme.primary, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ExpenseCategory.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((c) {
        final selected = c == _category;
        return GestureDetector(
          onTap: () => setState(() => _category = c),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? c.color.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? c.color : AppTheme.border,
                width: selected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  c.icon,
                  size: 16,
                  color: selected ? c.color : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  c.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? c.color : AppTheme.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}