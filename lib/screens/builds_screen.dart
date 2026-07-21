import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class BuildsScreen extends StatelessWidget {
  const BuildsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final builds = provider.savedBuilds;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Мои сборки'),
        actions: [
          if (builds.length >= 2)
            TextButton.icon(
              icon: const Icon(Icons.compare_arrows, color: Colors.white, size: 18),
              label: const Text('Сравнить', style: TextStyle(color: Colors.white)),
              onPressed: () => _showCompareBuildPicker(context, provider, builds),
            ),
        ],
      ),
      body: builds.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_border, size: 80,
                      color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text('Нет сохранённых сборок',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text(
                    'Создайте сборку и сохраните её\nдля сравнения или повторного просмотра',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Создать сборку'),
                    onPressed: () => context.go('/builder'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: builds.length,
              itemBuilder: (ctx, i) => _BuildCard(
                pcBuild: builds[i],
                onLoad: () {
                  provider.loadSavedBuild(builds[i]);
                  context.go('/builder');
                },
                onDelete: () {
                  provider.deleteSavedBuild(builds[i].id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Сборка удалена')),
                  );
                },
              ),
            ),
    );
  }

  void _showCompareBuildPicker(
      BuildContext context, AppProvider provider, builds) {
    String? firstId;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Выберите сборки для сравнения'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: builds.length,
              itemBuilder: (_, i) {
                final b = builds[i];
                final isSelected = firstId == b.id;
                return CheckboxListTile(
                  title: Text(b.name),
                  subtitle: Text(
                      '${b.components.length} компонентов · ${_fmt(b.totalPrice)} ₽'),
                  value: isSelected,
                  onChanged: (v) {
                    setState(() {
                      firstId = v == true ? b.id : null;
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: firstId == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      context.push('/compare-builds?id=$firstId');
                    },
              child: const Text('Сравнить'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double p) => p.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
}

class _BuildCard extends StatelessWidget {
  final dynamic pcBuild;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  const _BuildCard(
      {required this.pcBuild, required this.onLoad, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final categories = ComponentCategory.values
        .where((c) => pcBuild.components.containsKey(c))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.computer, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pcBuild.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${_fmt(pcBuild.totalPrice)} ₽',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Component chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: categories.map((cat) {
                final comp = pcBuild.components[cat];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cat.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: cat.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 12, color: cat.color),
                      const SizedBox(width: 4),
                      Text(
                        comp.model,
                        style: TextStyle(
                          fontSize: 11,
                          color: cat.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Missing components
          if (!pcBuild.isComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppTheme.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Сборка неполная (${pcBuild.components.length}/8 компонентов)',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.warning),
                  ),
                ],
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  '${pcBuild.components.length} компонентов',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Удалить', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onLoad,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Загрузить', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double p) => p.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
}
