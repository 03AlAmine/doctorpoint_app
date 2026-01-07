
import 'package:flutter/material.dart';

class Specialty {
  final String id;
  final String name;
  final String icon;
  final String description;
  final int doctorCount;
  final Color color;

  Specialty({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.doctorCount,
    required this.color,
  });

  factory Specialty.fromMap(Map<String, dynamic> data, String id) {
    return Specialty(
      id: id,
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      description: data['description'] ?? '',
      doctorCount: data['doctorCount'] ?? 0,
      color: _parseColor(data['color']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'description': description,
      'doctorCount': doctorCount,
      'color': _colorToString(color),
    };
  }

  static Color _parseColor(dynamic colorData) {
    if (colorData is String) {
      final buffer = StringBuffer();
      if (colorData.length == 6 || colorData.length == 7) {
        buffer.write('ff');
      }
      buffer.write(colorData.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } else if (colorData is int) {
      return Color(colorData);
    }
    return Colors.blue;
  }

  static String _colorToString(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }

  Specialty copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    int? doctorCount,
    Color? color,
  }) {
    return Specialty(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      doctorCount: doctorCount ?? this.doctorCount,
      color: color ?? this.color,
    );
  }
}