import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../data/components.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final items = provider.compareComponents;

    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сравнение')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.compare_arrows, size: 80,
                  color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              const Text('Нет товаров для сравнения',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Добавьте до 3 компонентов\nодного типа',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('В каталог'),
              ),
            ],
          ),
        ),
      );
    }

    // Collect all spec keys
    final allKeys = <String>{};
    for (final c in items) {
      allKeys.addAll(c.specs.keys);
    }

    // Find differing keys
    final differingKeys = allKeys.where((key) {
      final values = items.map((c) => c.specs[key]).toSet();
      return values.length > 1 || values.contains(null);
    }).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сравнение'),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearCompare();
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header row with component names
          Container(
            color: Colors.white,
            child: Row(
              children: [
                const SizedBox(width: 120),
                ...items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: c.category.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(c.category.icon,
                                color: c.category.color),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.brand,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            c.model,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_fmt(c.price)} ₽',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent,
                            ),
                          ),
                          // Swap button
                          GestureDetector(
                            onTap: () => _showSwapDialog(context, provider, i),
                            child: Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.chip,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.swap_horiz,
                                      size: 12, color: AppTheme.primary),
                                  SizedBox(width: 3),
                                  Text('Заменить',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.primary)),
                                ],
                              ),
                            ),
                          ),
                          // Remove button
                          GestureDetector(
                            onTap: () => provider.removeFromCompare(c.id),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close,
                                      size: 10, color: AppTheme.error),
                                  SizedBox(width: 3),
                                  Text('Убрать',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.error)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Legend
          Container(
            color: const Color(0xFFFFF3CD),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppTheme.accent),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Подсвечены отличающиеся характеристики',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Specs comparison table
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: allKeys.map((key) {
                  final isDiff = differingKeys.contains(key);
                  final values = items.map((c) => c.specs[key] ?? '—').toList();

                  return Container(
                    decoration: BoxDecoration(
                      color: isDiff
                          ? AppTheme.accent.withOpacity(0.06)
                          : Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.divider),
                        left: isDiff
                            ? const BorderSide(
                                color: AppTheme.accent, width: 3)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              key,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        ...values.map((v) => Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: Text(
                                  v,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isDiff
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isDiff
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSwapDialog(
      BuildContext context, AppProvider provider, int index) {
    final current = provider.compareComponents[index];
    final sameCategory = allComponents
        .where((c) => c.category == current.category && c.id != current.id)
        .toList();

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Выберите замену',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          ...sameCategory.map(
            (c) => ListTile(
              leading: Icon(c.category.icon, color: c.category.color),
              title: Text(c.name, style: const TextStyle(fontSize: 14)),
              subtitle: Text('${_fmt(c.price)} ₽',
                  style: const TextStyle(color: AppTheme.accent)),
              onTap: () {
                provider.swapCompare(index, c);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static String _fmt(double price) {
    return price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }
}
