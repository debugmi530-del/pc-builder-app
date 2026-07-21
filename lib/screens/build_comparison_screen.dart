import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../models/pc_build.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class BuildComparisonScreen extends StatelessWidget {
  final String buildId1;
  final String buildId2;

  const BuildComparisonScreen({
    super.key,
    required this.buildId1,
    required this.buildId2,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final b1 = provider.savedBuilds.where((b) => b.id == buildId1).firstOrNull;
    final b2 = provider.savedBuilds.where((b) => b.id == buildId2).firstOrNull;

    if (b1 == null || b2 == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сравнение сборок')),
        body: const Center(child: Text('Сборки не найдены')),
      );
    }

    return _BuildComparisonView(build1: b1, build2: b2);
  }
}

class _BuildComparisonView extends StatelessWidget {
  final PcBuild build1;
  final PcBuild build2;

  const _BuildComparisonView({required this.build1, required this.build2});

  @override
  Widget build(BuildContext context) {
    final cheaper = build1.totalPrice <= build2.totalPrice ? 0 : 1;
    final priceDiff = (build1.totalPrice - build2.totalPrice).abs();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Сравнение сборок'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Header — two build names + prices
          Container(
            color: Colors.white,
            child: Row(
              children: [
                const SizedBox(width: 100),
                _BuildHeader(build: build1, isCheaper: cheaper == 0),
                _BuildHeader(build: build2, isCheaper: cheaper == 1),
              ],
            ),
          ),

          // Price diff banner
          if (priceDiff > 0)
            Container(
              color: AppTheme.primary.withOpacity(0.07),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.savings_outlined,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${cheaper == 0 ? build1.name : build2.name} дешевле на ${_fmt(priceDiff)} ₽',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Legend
          Container(
            color: const Color(0xFFFFF3CD),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppTheme.accent),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Подсвечены отличающиеся позиции',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Category rows
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: ComponentCategory.values.map((cat) {
                  final c1 = build1.components[cat];
                  final c2 = build2.components[cat];
                  final isDiff = c1?.id != c2?.id;
                  final bothMissing = c1 == null && c2 == null;
                  if (bothMissing) return const SizedBox.shrink();

                  return Container(
                    decoration: BoxDecoration(
                      color: isDiff
                          ? AppTheme.accent.withOpacity(0.05)
                          : Colors.white,
                      border: Border(
                        bottom:
                            BorderSide(color: AppTheme.divider),
                        left: isDiff
                            ? const BorderSide(
                                color: AppTheme.accent, width: 3)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category label
                        SizedBox(
                          width: 100,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(cat.icon,
                                    size: 16, color: cat.color),
                                const SizedBox(height: 4),
                                Text(
                                  cat.shortName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cat.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Build 1 component
                        _ComponentCell(
                            component: c1, isDiff: isDiff),
                        // Build 2 component
                        _ComponentCell(
                            component: c2, isDiff: isDiff),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom totals
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                0, 12, 0, 12 + MediaQuery.of(context).padding.bottom),
            child: Row(
              children: [
                const SizedBox(width: 100),
                Expanded(
                  child: _PriceTotal(
                    build: build1,
                    isCheaper: cheaper == 0,
                  ),
                ),
                Expanded(
                  child: _PriceTotal(
                    build: build2,
                    isCheaper: cheaper == 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double p) =>
      p.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
}

class _BuildHeader extends StatelessWidget {
  final PcBuild build;
  final bool isCheaper;

  const _BuildHeader({required this.build, required this.isCheaper});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.computer,
                  color: AppTheme.primary, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              build.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${build.components.length} комп.',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
            if (isCheaper)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Дешевле',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ComponentCell extends StatelessWidget {
  final Component? component;
  final bool isDiff;

  const _ComponentCell({this.component, required this.isDiff});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: component == null
            ? const Center(
                child: Text(
                  '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    component!.brand,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDiff
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    component!.model,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isDiff
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fmt(component!.price)} ₽',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static String _fmt(double p) =>
      p.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
}

class _PriceTotal extends StatelessWidget {
  final PcBuild build;
  final bool isCheaper;

  const _PriceTotal({required this.build, required this.isCheaper});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Итого',
          style: const TextStyle(
              fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          '${_fmt(build.totalPrice)} ₽',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isCheaper ? AppTheme.success : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  static String _fmt(double p) =>
      p.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]} ',
      );
}
