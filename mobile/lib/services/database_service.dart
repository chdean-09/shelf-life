import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pantry_item.dart';

class DatabaseService {
  static late Isar isar;

  // Initialize the database (call this once at app start)
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open(
      [PantryItemSchema], // Register your model
      directory: dir.path,
    );
  }

  // Add item
  Future<void> addItem(PantryItem item) async {
    await isar.writeTxn(() async {
      await isar.pantryItems.put(item);
    });
  }

  // Get all items
  Future<List<PantryItem>> getAllItems() async {
    return await isar.pantryItems.where().findAll();
  }

  // Delete item
  Future<void> deleteItem(int id) async {
    await isar.writeTxn(() async {
      await isar.pantryItems.delete(id);
    });
  }

  // Get items expiring soon (within 3 days)
  Future<List<PantryItem>> getExpiringSoon() async {
    final threeDaysFromNow = DateTime.now().add(Duration(days: 3));

    return await isar.pantryItems
        .filter()
        .expiryDateLessThan(threeDaysFromNow)
        .sortByExpiryDate()
        .findAll();
  }
}
