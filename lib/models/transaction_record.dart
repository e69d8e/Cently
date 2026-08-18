import 'category.dart';

class TransactionRecord {
  final String id;
  final double amount;
  final CategoryType type;
  final String categoryId;
  final String categoryName;
  final String name; // Name/item (e.g. "早餐" or custom entered name)
  final DateTime dateTime;
  final String? remark;
  final DateTime createdAt;

  TransactionRecord({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.dateTime,
    this.remark,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  TransactionRecord copyWith({
    String? id,
    double? amount,
    CategoryType? type,
    String? categoryId,
    String? categoryName,
    String? name,
    DateTime? dateTime,
    String? remark,
    DateTime? createdAt,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      dateTime: dateTime ?? this.dateTime,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'name': name,
      'timestamp': dateTime.millisecondsSinceEpoch,
      'remark': remark,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: CategoryType.fromString(map['type'] as String),
      categoryId: map['categoryId'] as String,
      categoryName: map['categoryName'] as String,
      name: map['name'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      remark: map['remark'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? map['timestamp'] as int,
      ),
    );
  }
}
