class PresetItem {
  final String id;
  final String categoryId;
  final String name;
  final int sortOrder;
  final bool isDefault;

  PresetItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.sortOrder = 0,
    this.isDefault = false,
  });

  PresetItem copyWith({
    String? id,
    String? categoryId,
    String? name,
    int? sortOrder,
    bool? isDefault,
  }) {
    return PresetItem(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'name': name,
      'sortOrder': sortOrder,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory PresetItem.fromMap(Map<String, dynamic> map) {
    return PresetItem(
      id: map['id'] as String,
      categoryId: map['categoryId'] as String,
      name: map['name'] as String,
      sortOrder: map['sortOrder'] as int? ?? 0,
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
    );
  }
}
