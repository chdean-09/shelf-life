import 'package:isar/isar.dart';

part 'pantry_item.g.dart';

@collection
class PantryItem {
  Id id = Isar.autoIncrement;

  late String name;
  
  late DateTime expiryDate;
  
  late DateTime createdAt;

  // Constructor
  PantryItem({
    required this.name,
    required this.expiryDate,
  }) {
    createdAt = DateTime.now();
  }

  // Empty constructor for Isar
  PantryItem.empty();
}