import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../data/components.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class FilterPanel extends StatelessWidget {
  final ComponentCategory category;
  const FilterPanel({super.key, required this.category});

  // Get unique values for a spec key across all components in this category
  List<String> _uniqueValues(List<Component> components, String key) {
    return components
        .map((c) => c.specs[key])
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }

  // Get relevant filter keys per category
  List<String> _filterKeys() {
    switch (category) {
      case ComponentCategory.cpu:
        return ['Сокет', 'Техпроцесс', 'TDP'];
      case ComponentCategory.gpu:
        return ['Видеопамять', 'Интерфейс', 'TDP'];
      case ComponentCategory.ram:
        return ['Тип', 'Объём', 'Частота'];
      case ComponentCategory.storage:
        return ['Форм-фактор', 'Интерфейс', 'Ёмкость'];
      case ComponentCategory.psu:
        return ['Мощность', 'Сертификат', 'Модульность'];
      case ComponentCategory.motherboard:
        return ['Сокет', 'Чипсет', 'Форм-фактор'];
      case ComponentCategory.pcCase:
        return ['Тип', 'Материнские платы'];
      case ComponentCategory.cooling:
        return ['Тип', 'TDP'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final components = getByCategory(category);
    final filterKeys = _filterKeys();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('Фильтры',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (provider.activeFilters.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        provider.clearFiltersForCategory(category.key),
                    child: const Text('Сбросить всё',
                        style: TextStyle(color: AppTheme.error, fontSize: 13)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Готово',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter sections
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: filterKeys.map((key) {
                final values = _uniqueValues(components, key);
                if (values.isEmpty) return const SizedBox.shrink();

                final activeSet = provider.activeFilters[key] ?? {};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: values.map((v) {
                          final isActive = activeSet.contains(v);
                          return FilterChip(
                            label: Text(v),
                            selected: isActive,
                            onSelected: (_) =>
                                provider.toggleFilter(key, v),
                            backgroundColor: Colors.white,
                            selectedColor: AppTheme.chip,
                            checkmarkColor: AppTheme.primary,
                            side: BorderSide(
                              color: isActive
                                  ? AppTheme.primary
                                  : AppTheme.divider,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isActive
                                  ? AppTheme.primary
                                  : AppTheme.textPrimary,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),

          // Apply button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    provider.activeFilters.isEmpty
                        ? 'Применить'
                        : 'Применить (${provider.activeFilters.values.fold<int>(0, (s, v) => s + v.length)} активных)',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
