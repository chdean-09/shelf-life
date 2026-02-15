import 'package:isar/isar.dart';

part 'waste_log.g.dart';

@collection
class WasteLog {
  Id id = Isar.autoIncrement;

  late String itemName;

  late String category;

  late double estimatedPrice;

  late DateTime wastedDate;

  late DateTime createdAt;

  // Constructor
  WasteLog({
    required this.itemName,
    required this.category,
    required this.estimatedPrice,
  }) {
    wastedDate = DateTime.now();
    createdAt = DateTime.now();
  }

  // Empty constructor for Isar
  WasteLog.empty();

  /// Converts to JSON for API sync.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'category': category,
      'estimated_price': estimatedPrice,
      'wasted_date': wastedDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a WasteLog from JSON (API response).
  factory WasteLog.fromJson(Map<String, dynamic> json) {
    final log = WasteLog(
      itemName: json['item_name'] as String,
      category: json['category'] as String? ?? 'other',
      estimatedPrice: (json['estimated_price'] as num).toDouble(),
    );
    if (json['id'] != null) log.id = json['id'] as int;
    if (json['wasted_date'] != null) {
      log.wastedDate = DateTime.parse(json['wasted_date'] as String);
    }
    if (json['created_at'] != null) {
      log.createdAt = DateTime.parse(json['created_at'] as String);
    }
    return log;
  }
}
