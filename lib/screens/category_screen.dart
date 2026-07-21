import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../widgets/component_card.dart';
import '../widgets/filter_panel.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryKey;
  const CategoryScreen({super.key, required this.categoryKey});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late ComponentCategory _category;
  final _searchCtrl = TextEditingController();
  String _localSearch = '';

  @override
  void initState() {
    super.initState();
    _category = ComponentCategory.values.firstWhere(
      (c) => c.key == widget.categoryKey,
      orElse: () => ComponentCategory.cpu,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    var components = provider.filteredComponents(_category);

    // Local search filter on top of provider filter
    if (_localSearch.isNotEmpty) {
      final q = _localSearch.toLowerCase();
      components = components.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.brand.toLowerCase().contains(q)
      ).toList();
    }

    final sortOptions = {
      'price_asc': 'Сначала дешевле',
      'price_desc': 'Сначала дороже',
      'name_asc': 'По названию (А-Я)',
      'name_desc': 'По названию (Я-А)',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_category.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: provider.activeFilters.isNotEmpty,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => _showFilterPanel(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: provider.setSortBy,
            itemBuilder: (_) => sortOptions.entries
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Row(
                        children: [
                          if (provider.sortBy == e.key)
                            const Icon(Icons.check, size: 16, color: AppTheme.primary),
                          if (provider.sortBy != e.key)
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(e.value),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Поиск в ${_category.displayName.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _localSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _localSearch = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _localSearch = v),
            ),
          ),

          // Active filters row
          if (provider.activeFilters.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  ...provider.activeFilters.entries.expand((entry) =>
                    entry.value.map((v) => Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text('${entry.key}: $v'),
                        onDeleted: () => provider.toggleFilter(entry.key, v),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        backgroundColor: AppTheme.chip,
                        labelStyle: const TextStyle(
                          fontSize: 11, color: AppTheme.chipText),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ))
                  ),
                  TextButton(
                    onPressed: () => provider.clearFiltersForCategory(_category.key),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Сбросить всё',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ],
              ),
            ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Найдено: ${components.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Component list
          Expanded(
            child: components.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 64,
                            color: AppTheme.textSecondary),
                        const SizedBox(height: 12),
                        const Text('Ничего не найдено',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: components.length,
                    itemBuilder: (ctx, i) => ComponentCard(
                      component: components[i],
                      onTap: () =>
                          context.push('/component/${components[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showFilterPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterPanel(category: _category),
    );
  }
}
