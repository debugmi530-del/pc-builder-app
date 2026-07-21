import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/component.dart';
import '../models/pc_build.dart';
import '../data/components.dart';

class AppProvider extends ChangeNotifier {
  // ── Build state ──
  PcBuild _currentBuild = PcBuild(
    id: 'current',
    name: 'Моя сборка',
    createdAt: DateTime.now(),
    components: {},
  );
  List<PcBuild> _savedBuilds = [];

  // ── Comparison ──
  List<Component> _compareComponents = [];
  PcBuild? _compareBuild1;
  PcBuild? _compareBuild2;

  // ── Filters & Search ──
  String _searchQuery = '';
  Map<String, Set<String>> _activeFilters = {};
  String _sortBy = 'price_asc';

  PcBuild get currentBuild => _currentBuild;
  List<PcBuild> get savedBuilds => _savedBuilds;
  List<Component> get compareComponents => _compareComponents;
  PcBuild? get compareBuild1 => _compareBuild1;
  PcBuild? get compareBuild2 => _compareBuild2;
  String get searchQuery => _searchQuery;
  Map<String, Set<String>> get activeFilters => _activeFilters;
  String get sortBy => _sortBy;

  AppProvider() {
    _load();
  }

  // ─── Build Management ───

  void addToBuild(Component component) {
    final updated = Map<ComponentCategory, Component>.from(_currentBuild.components);
    updated[component.category] = component;
    _currentBuild = _currentBuild.copyWith(components: updated);
    notifyListeners();
    _save();
  }

  void removeFromBuild(ComponentCategory category) {
    final updated = Map<ComponentCategory, Component>.from(_currentBuild.components);
    updated.remove(category);
    _currentBuild = _currentBuild.copyWith(components: updated);
    notifyListeners();
    _save();
  }

  void setBuildName(String name) {
    _currentBuild = _currentBuild.copyWith(name: name);
    notifyListeners();
    _save();
  }

  void clearBuild() {
    _currentBuild = PcBuild(
      id: 'current',
      name: 'Моя сборка',
      createdAt: DateTime.now(),
      components: {},
    );
    notifyListeners();
    _save();
  }

  void saveBuild() {
    final build = PcBuild(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _currentBuild.name,
      createdAt: DateTime.now(),
      components: Map.from(_currentBuild.components),
    );
    _savedBuilds = [build, ..._savedBuilds];
    notifyListeners();
    _save();
  }

  void deleteSavedBuild(String id) {
    _savedBuilds = _savedBuilds.where((b) => b.id != id).toList();
    notifyListeners();
    _save();
  }

  void loadSavedBuild(PcBuild build) {
    _currentBuild = PcBuild(
      id: 'current',
      name: build.name,
      createdAt: DateTime.now(),
      components: Map.from(build.components),
    );
    notifyListeners();
    _save();
  }

  // ─── Compatibility Check ───

  CompatibilityResult checkCompatibility() {
    final components = _currentBuild.components;
    final errors = <String>[];
    final warnings = <String>[];

    final cpu = components[ComponentCategory.cpu];
    final mb = components[ComponentCategory.motherboard];
    final ram = components[ComponentCategory.ram];
    final gpu = components[ComponentCategory.gpu];
    final psu = components[ComponentCategory.psu];
    final pcCase = components[ComponentCategory.pcCase];
    final cooling = components[ComponentCategory.cooling];

    // CPU <-> Motherboard socket
    if (cpu != null && mb != null) {
      if (cpu.socket != mb.socket) {
        errors.add('Процессор ${cpu.brand} ${cpu.model} (${cpu.socket}) несовместим с платой ${mb.brand} ${mb.model} (${mb.socket})');
      }
    }

    // RAM type <-> Motherboard
    if (ram != null && mb != null) {
      if (mb.memoryTypes.isNotEmpty && !mb.memoryTypes.contains(ram.memoryType)) {
        errors.add('Память ${ram.brand} ${ram.model} (${ram.memoryType}) несовместима с платой ${mb.brand} ${mb.model}');
      }
    }

    // CPU <-> RAM (DDR type matching)
    if (cpu != null && ram != null) {
      if (cpu.memoryTypes.isNotEmpty && !cpu.memoryTypes.contains(ram.memoryType)) {
        warnings.add('Процессор ${cpu.model} поддерживает ${cpu.memoryTypes.join('/')}, установлена ${ram.memoryType}');
      }
    }

    // Cooler <-> CPU socket
    if (cooling != null && cpu != null && cpu.socket != null) {
      if (cooling.supportedSockets.isNotEmpty &&
          !cooling.supportedSockets.contains(cpu.socket)) {
        errors.add('Кулер ${cooling.brand} ${cooling.model} не поддерживает сокет ${cpu.socket}');
      }
    }

    // Case <-> Motherboard form factor
    if (pcCase != null && mb != null) {
      if (mb.formFactor != null &&
          pcCase.supportedFormFactors.isNotEmpty &&
          !pcCase.supportedFormFactors.contains(mb.formFactor)) {
        errors.add('Корпус ${pcCase.brand} ${pcCase.model} не поддерживает форм-фактор ${mb.formFactor}');
      }
    }

    // Power budget
    int totalTdp = 0;
    if (cpu != null) totalTdp += cpu.tdp ?? 0;
    if (gpu != null) totalTdp += gpu.powerDraw ?? 0;
    totalTdp += 100; // base system

    int requiredPower = (totalTdp * 1.3).round();

    if (psu != null) {
      if ((psu.powerDraw ?? 0) < requiredPower) {
        errors.add('Блок питания ${psu.brand} ${psu.model} (${psu.powerDraw} Вт) может не хватить для системы (рекомендуется ${requiredPower} Вт)');
      } else if ((psu.powerDraw ?? 0) < totalTdp + 50) {
        warnings.add('Блок питания работает на высокой нагрузке. Рекомендуется запас 20-30%');
      }
    }

    // Cooler TDP warning
    if (cooling != null && cpu != null) {
      final coolerTdp = cooling.tdp ?? 0;
      final cpuTdp = cpu.tdp ?? 0;
      if (coolerTdp < cpuTdp) {
        warnings.add('TDP кулера (${coolerTdp} Вт) может быть недостаточен для процессора (${cpuTdp} Вт)');
      }
    }

    return CompatibilityResult(
      isCompatible: errors.isEmpty,
      warnings: warnings,
      errors: errors,
      totalTdp: totalTdp,
      requiredPower: requiredPower,
    );
  }

  // ─── Compare Components ───

  void addToCompare(Component component) {
    if (_compareComponents.length >= 3) {
      _compareComponents = [_compareComponents[1], _compareComponents[2], component];
    } else {
      _compareComponents = [..._compareComponents, component];
    }
    notifyListeners();
  }

  void removeFromCompare(String id) {
    _compareComponents = _compareComponents.where((c) => c.id != id).toList();
    notifyListeners();
  }

  void swapCompare(int index, Component newComponent) {
    final updated = List<Component>.from(_compareComponents);
    if (index < updated.length) {
      updated[index] = newComponent;
    }
    _compareComponents = updated;
    notifyListeners();
  }

  void clearCompare() {
    _compareComponents = [];
    notifyListeners();
  }

  bool isInCompare(String id) => _compareComponents.any((c) => c.id == id);

  // Compare builds
  void setCompareBuild1(PcBuild build) {
    _compareBuild1 = build;
    notifyListeners();
  }

  void setCompareBuild2(PcBuild build) {
    _compareBuild2 = build;
    notifyListeners();
  }

  // ─── Filters & Sorting ───

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void toggleFilter(String key, String value) {
    final current = Map<String, Set<String>>.from(_activeFilters);
    final set = Set<String>.from(current[key] ?? {});
    if (set.contains(value)) {
      set.remove(value);
    } else {
      set.add(value);
    }
    if (set.isEmpty) {
      current.remove(key);
    } else {
      current[key] = set;
    }
    _activeFilters = current;
    notifyListeners();
  }

  void clearFiltersForCategory(String category) {
    _activeFilters = {};
    notifyListeners();
  }

  List<Component> filteredComponents(ComponentCategory category) {
    var list = getByCategory(category);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.brand.toLowerCase().contains(q) ||
        c.description.toLowerCase().contains(q) ||
        c.specs.values.any((v) => v.toLowerCase().contains(q))
      ).toList();
    }

    // Apply filters
    for (final entry in _activeFilters.entries) {
      final key = entry.key;
      final values = entry.value;
      list = list.where((c) {
        final specVal = c.specs[key];
        return specVal != null && values.contains(specVal);
      }).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'name_asc':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        list.sort((a, b) => b.name.compareTo(a.name));
        break;
    }

    return list;
  }

  List<Component> searchAll(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return allComponents.where((c) =>
      c.name.toLowerCase().contains(q) ||
      c.brand.toLowerCase().contains(q) ||
      c.model.toLowerCase().contains(q) ||
      c.category.displayName.toLowerCase().contains(q)
    ).toList();
  }

  // ─── Persistence ───

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save current build component IDs
      final buildMap = _currentBuild.components.map(
        (k, v) => MapEntry(k.key, v.id),
      );
      await prefs.setString('current_build_name', _currentBuild.name);
      await prefs.setString('current_build', jsonEncode(buildMap));

      // Save saved builds
      final buildsJson = _savedBuilds.map((b) => jsonEncode(b.toJson())).toList();
      await prefs.setStringList('saved_builds', buildsJson);
    } catch (e) {
      // ignore storage errors
    }
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buildName = prefs.getString('current_build_name') ?? 'Моя сборка';
      final buildJson = prefs.getString('current_build');
      if (buildJson != null) {
        final map = jsonDecode(buildJson) as Map<String, dynamic>;
        final components = <ComponentCategory, Component>{};
        for (final entry in map.entries) {
          final cat = ComponentCategory.values.firstWhere(
            (c) => c.key == entry.key,
            orElse: () => ComponentCategory.cpu,
          );
          final comp = findComponentById(entry.value as String);
          if (comp != null) components[cat] = comp;
        }
        _currentBuild = PcBuild(
          id: 'current',
          name: buildName,
          createdAt: DateTime.now(),
          components: components,
        );
      }

      // Load saved builds
      final buildsJson = prefs.getStringList('saved_builds') ?? [];
      _savedBuilds = buildsJson.map((json) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        final compIds = (data['componentIds'] as Map<String, dynamic>?) ?? {};
        final components = <ComponentCategory, Component>{};
        for (final entry in compIds.entries) {
          final cat = ComponentCategory.values.firstWhere(
            (c) => c.key == entry.key,
            orElse: () => ComponentCategory.cpu,
          );
          final comp = findComponentById(entry.value as String);
          if (comp != null) components[cat] = comp;
        }
        return PcBuild(
          id: data['id'] ?? '',
          name: data['name'] ?? 'Сборка',
          createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
          components: components,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      // ignore load errors
    }
  }

  bool isInCurrentBuild(String componentId) {
    return _currentBuild.components.values.any((c) => c.id == componentId);
  }
}
