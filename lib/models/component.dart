import 'package:flutter/material.dart';

enum ComponentCategory {
  cpu,
  gpu,
  ram,
  storage,
  psu,
  motherboard,
  pcCase,
  cooling,
}

extension ComponentCategoryExt on ComponentCategory {
  String get displayName {
    switch (this) {
      case ComponentCategory.cpu: return 'Процессоры';
      case ComponentCategory.gpu: return 'Видеокарты';
      case ComponentCategory.ram: return 'Оперативная память';
      case ComponentCategory.storage: return 'Накопители';
      case ComponentCategory.psu: return 'Блоки питания';
      case ComponentCategory.motherboard: return 'Материнские платы';
      case ComponentCategory.pcCase: return 'Корпуса';
      case ComponentCategory.cooling: return 'Охлаждение';
    }
  }

  String get shortName {
    switch (this) {
      case ComponentCategory.cpu: return 'CPU';
      case ComponentCategory.gpu: return 'GPU';
      case ComponentCategory.ram: return 'RAM';
      case ComponentCategory.storage: return 'Накопитель';
      case ComponentCategory.psu: return 'БП';
      case ComponentCategory.motherboard: return 'Мат. плата';
      case ComponentCategory.pcCase: return 'Корпус';
      case ComponentCategory.cooling: return 'Охлаждение';
    }
  }

  String get key {
    switch (this) {
      case ComponentCategory.cpu: return 'cpu';
      case ComponentCategory.gpu: return 'gpu';
      case ComponentCategory.ram: return 'ram';
      case ComponentCategory.storage: return 'storage';
      case ComponentCategory.psu: return 'psu';
      case ComponentCategory.motherboard: return 'motherboard';
      case ComponentCategory.pcCase: return 'case';
      case ComponentCategory.cooling: return 'cooling';
    }
  }

  IconData get icon {
    switch (this) {
      case ComponentCategory.cpu: return Icons.memory;
      case ComponentCategory.gpu: return Icons.videogame_asset;
      case ComponentCategory.ram: return Icons.storage;
      case ComponentCategory.storage: return Icons.save;
      case ComponentCategory.psu: return Icons.electrical_services;
      case ComponentCategory.motherboard: return Icons.developer_board;
      case ComponentCategory.pcCase: return Icons.computer;
      case ComponentCategory.cooling: return Icons.ac_unit;
    }
  }

  Color get color {
    switch (this) {
      case ComponentCategory.cpu: return const Color(0xFF3B82F6);
      case ComponentCategory.gpu: return const Color(0xFF10B981);
      case ComponentCategory.ram: return const Color(0xFF8B5CF6);
      case ComponentCategory.storage: return const Color(0xFFF59E0B);
      case ComponentCategory.psu: return const Color(0xFFEF4444);
      case ComponentCategory.motherboard: return const Color(0xFF06B6D4);
      case ComponentCategory.pcCase: return const Color(0xFF6B7280);
      case ComponentCategory.cooling: return const Color(0xFF3B82F6);
    }
  }
}

class Component {
  final String id;
  final String name;
  final String brand;
  final String model;
  final ComponentCategory category;
  final double price;
  final String description;
  final Map<String, String> specs;
  final List<String> keySpecs;

  // Compatibility fields
  final String? socket;
  final String? memoryType;
  final int? tdp;
  final int? powerDraw;
  final String? formFactor;
  final List<String> supportedSockets;
  final List<String> supportedFormFactors;
  final List<String> memoryTypes;

  const Component({
    required this.id,
    required this.name,
    required this.brand,
    required this.model,
    required this.category,
    required this.price,
    required this.description,
    required this.specs,
    required this.keySpecs,
    this.socket,
    this.memoryType,
    this.tdp,
    this.powerDraw,
    this.formFactor,
    this.supportedSockets = const [],
    this.supportedFormFactors = const [],
    this.memoryTypes = const [],
  });

  String get fullName => '$brand $model';
}

class CompatibilityResult {
  final bool isCompatible;
  final List<String> warnings;
  final List<String> errors;
  final int totalTdp;
  final int requiredPower;

  const CompatibilityResult({
    required this.isCompatible,
    required this.warnings,
    required this.errors,
    required this.totalTdp,
    required this.requiredPower,
  });
}
