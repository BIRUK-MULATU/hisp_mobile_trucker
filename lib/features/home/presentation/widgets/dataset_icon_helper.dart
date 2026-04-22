import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';

class DataSetIconHelper {
  DataSetIconHelper._();

  static const List<_IconConfig> _configs = [
    _IconConfig(
      keywords: ['maternal', 'reproductive', 'mother'],
      icon: Icons.people_alt_outlined,
      color: Color(0xFF1565C0),
    ),
    _IconConfig(
      keywords: ['child', 'neonatal', 'infant', 'baby'],
      icon: Icons.child_care_outlined,
      color: Color(0xFF0097A7),
    ),
    _IconConfig(
      keywords: ['hiv', 'aids', 'comprehensive'],
      icon: Icons.coronavirus_outlined,
      color: Color(0xFF6A1B9A),
    ),
    _IconConfig(
      keywords: ['nutrition', 'neutration', 'food'],
      icon: Icons.local_dining_outlined,
      color: Color(0xFF2E7D32),
    ),
    _IconConfig(
      keywords: ['monthly', 'dataset', 'common'],
      icon: Icons.assignment_outlined,
      color: Color(0xFFE53935),
    ),
    _IconConfig(
      keywords: ['health', 'post', 'facility'],
      icon: Icons.local_hospital_outlined,
      color: Color(0xFF1565C0),
    ),
    _IconConfig(
      keywords: ['report', 'data', 'record'],
      icon: Icons.bar_chart_outlined,
      color: Color(0xFF00796B),
    ),
  ];

  static IconData getIcon(String name) {
    final lower = name.toLowerCase();
    for (final config in _configs) {
      if (config.keywords.any((k) => lower.contains(k))) {
        return config.icon;
      }
    }
    return Icons.folder_outlined;
  }

  static Color getColor(String name) {
    final lower = name.toLowerCase();
    for (final config in _configs) {
      if (config.keywords.any((k) => lower.contains(k))) {
        return config.color;
      }
    }
    return AppColors.primary;
  }
}

class _IconConfig {
  final List<String> keywords;
  final IconData icon;
  final Color color;

  const _IconConfig({
    required this.keywords,
    required this.icon,
    required this.color,
  });
}
