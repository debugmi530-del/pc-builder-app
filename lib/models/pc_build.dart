import 'component.dart';

class PcBuild {
  final String id;
  final String name;
  final DateTime createdAt;
  final Map<ComponentCategory, Component> components;

  PcBuild({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.components,
  });

  double get totalPrice =>
      components.values.fold(0, (sum, c) => sum + c.price);

  int get totalTdp {
    int tdp = 0;
    if (components[ComponentCategory.cpu] != null) {
      tdp += components[ComponentCategory.cpu]!.tdp ?? 0;
    }
    if (components[ComponentCategory.gpu] != null) {
      tdp += components[ComponentCategory.gpu]!.powerDraw ?? 0;
    }
    return tdp;
  }

  int get recommendedPsu => (totalTdp * 1.3 + 100).round();

  bool get isComplete {
    const required = [
      ComponentCategory.cpu,
      ComponentCategory.gpu,
      ComponentCategory.ram,
      ComponentCategory.storage,
      ComponentCategory.psu,
      ComponentCategory.motherboard,
    ];
    return required.every((c) => components.containsKey(c));
  }

  PcBuild copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    Map<ComponentCategory, Component>? components,
  }) {
    return PcBuild(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      components: components ?? Map.from(this.components),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'componentIds': components.map(
        (k, v) => MapEntry(k.key, v.id),
      ),
    };
  }
}
