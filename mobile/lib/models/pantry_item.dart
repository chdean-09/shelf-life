import 'package:isar/isar.dart';

part 'pantry_item.g.dart';

/// Storage location for a pantry item.
enum StorageLocation {
  pantry,
  fridge,
  freezer,
}

@collection
class PantryItem {
  Id id = Isar.autoIncrement;

  late String name;

  late DateTime expiryDate;

  @enumerated
  late StorageLocation storageLocation;

  String? category;

  String? barcode;

  late DateTime createdAt;

  late DateTime updatedAt;

  @Index()
  late bool synced;

  // Constructor
  PantryItem({
    required this.name,
    required this.expiryDate,
    this.storageLocation = StorageLocation.fridge,
    this.category,
    this.barcode,
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
    synced = false;
  }

  // Empty constructor for Isar
  PantryItem.empty();

  /// Returns the number of days until this item expires.
  int get daysUntilExpiry =>
      expiryDate.difference(DateTime.now()).inDays;

  /// Returns true if the item is expired.
  bool get isExpired => daysUntilExpiry < 0;

  /// Returns true if the item expires within [days] days.
  bool isExpiringSoon(int days) => daysUntilExpiry <= days && !isExpired;

  /// Converts to JSON for API sync.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expiry_date': expiryDate.toIso8601String(),
      'storage_location': storageLocation.name,
      'category': category,
      'barcode': barcode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a PantryItem from JSON (API response).
  factory PantryItem.fromJson(Map<String, dynamic> json) {
    final item = PantryItem(
      name: json['name'] as String,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      storageLocation: StorageLocation.values.firstWhere(
        (e) => e.name == json['storage_location'],
        orElse: () => StorageLocation.fridge,
      ),
      category: json['category'] as String?,
      barcode: json['barcode'] as String?,
    );
    if (json['id'] != null) item.id = json['id'] as int;
    if (json['created_at'] != null) {
      item.createdAt = DateTime.parse(json['created_at'] as String);
    }
    if (json['updated_at'] != null) {
      item.updatedAt = DateTime.parse(json['updated_at'] as String);
    }
    item.synced = true;
    return item;
  }
}