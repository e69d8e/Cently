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
  final DateTime? deletedAt;

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
    this.deletedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isDeleted => deletedAt != null;

  int get remainingDays {
    if (deletedAt == null) return 30;
    final now = DateTime.now();
    final difference = now.difference(deletedAt!).inSeconds;
    final daysPassed = difference / (24 * 3600);
    final remaining = (30 - daysPassed).ceil();
    if (remaining < 0) return 0;
    if (remaining > 30) return 30;
    return remaining;
  }

  TransactionRecord copyWith({
    String? id,
    double? amount,
    CategoryType? type,
    String? categoryId,
    String? categoryName,
    String? name,
    DateTime? dateTime,
    String? remark,
    bool clearRemark = false,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return TransactionRecord(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      dateTime: dateTime ?? this.dateTime,
      remark: clearRemark ? null : (remark ?? this.remark),
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
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
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
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
      deletedAt: map['deletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deletedAt'] as int)
          : null,
    );
  }
}
