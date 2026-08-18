import 'package:flutter/material.dart';

enum CategoryType {
  expense,
  income;

  String get displayName => this == CategoryType.expense ? '支出' : '收入';

  static CategoryType fromString(String value) {
    return value == 'income' ? CategoryType.income : CategoryType.expense;
  }
}

class Category {
  final String id;
  final String name;
  final CategoryType type;
  final String iconKey;
  final int colorValue;
  final int sortOrder;
  final bool isDefault;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorValue,
    this.sortOrder = 0,
    this.isDefault = false,
  });

  Color get color => Color(colorValue);

  Category copyWith({
    String? id,
    String? name,
    CategoryType? type,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'sortOrder': sortOrder,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CategoryType.fromString(map['type'] as String),
      iconKey: map['iconKey'] as String? ?? 'category',
      colorValue: map['colorValue'] as int? ?? 0xFF1E293B,
      sortOrder: map['sortOrder'] as int? ?? 0,
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
    );
  }
}
