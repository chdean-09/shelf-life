import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pantry_item.dart';
import '../models/waste_log.dart';
import '../models/product.dart';

class DatabaseService {
  static late Isar isar;

  // Initialize the database (call this once at app start)
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open(
      [PantryItemSchema, WasteLogSchema, ProductSchema],
      directory: dir.path,
    );
  }

  // ─── Pantry Items ───────────────────────────────────────────

  /// Add or update a pantry item.
  Future<void> addItem(PantryItem item) async {
    item.synced = false;
    item.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.pantryItems.put(item);
    });
  }

  /// Get all pantry items sorted by expiry date.
  Future<List<PantryItem>> getAllItems() async {
    return await isar.pantryItems.where().sortByExpiryDate().findAll();
  }

  /// Get items expiring within [days] days.
  Future<List<PantryItem>> getExpiringSoon({int days = 3}) async {
    final threshold = DateTime.now().add(Duration(days: days));
    return await isar.pantryItems
        .filter()
        .expiryDateLessThan(threshold)
        .expiryDateGreaterThan(DateTime.now().subtract(const Duration(days: 1)))
        .sortByExpiryDate()
        .findAll();
  }

  /// Update a pantry item.
  Future<void> updateItem(PantryItem item) async {
    item.synced = false;
    item.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.pantryItems.put(item);
    });
  }

  /// Delete a pantry item by ID.
  Future<void> deleteItem(int id) async {
    await isar.writeTxn(() async {
      await isar.pantryItems.delete(id);
    });
  }

  /// Get all unsynced items.
  Future<List<PantryItem>> getUnsyncedItems() async {
    return await isar.pantryItems
        .filter()
        .syncedEqualTo(false)
        .findAll();
  }

  /// Mark items as synced.
  Future<void> markItemsSynced(List<PantryItem> items) async {
    await isar.writeTxn(() async {
      for (var item in items) {
        item.synced = true;
        await isar.pantryItems.put(item);
      }
    });
  }

  // ─── Waste Logs ─────────────────────────────────────────────

  /// Add a waste log entry.
  Future<void> addWasteLog(WasteLog log) async {
    await isar.writeTxn(() async {
      await isar.wasteLogs.put(log);
    });
  }

  /// Get all waste logs.
  Future<List<WasteLog>> getAllWasteLogs() async {
    return await isar.wasteLogs.where().sortByWastedDateDesc().findAll();
  }

  /// Get waste logs for the current month.
  Future<List<WasteLog>> getMonthlyWasteLogs() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return await isar.wasteLogs
        .filter()
        .wastedDateGreaterThan(startOfMonth)
        .findAll();
  }

  /// Get total waste amount for the current month.
  Future<double> getMonthlyWasteTotal() async {
    final logs = await getMonthlyWasteLogs();
    return logs.fold<double>(0.0, (sum, log) => sum + log.estimatedPrice);
  }

  /// Get waste grouped by category for the current month.
  Future<Map<String, double>> getMonthlyWasteByCategory() async {
    final logs = await getMonthlyWasteLogs();
    final Map<String, double> byCategory = {};
    for (var log in logs) {
      byCategory[log.category] =
          (byCategory[log.category] ?? 0) + log.estimatedPrice;
    }
    return byCategory;
  }

  // ─── Product Cache ──────────────────────────────────────────

  /// Find a cached product by barcode.
  Future<Product?> findProductByBarcode(String barcode) async {
    return await isar.products
        .filter()
        .barcodeEqualTo(barcode)
        .findFirst();
  }

  /// Cache a product from API response.
  Future<void> cacheProduct(Product product) async {
    await isar.writeTxn(() async {
      await isar.products.put(product);
    });
  }

  // ─── Utilities ──────────────────────────────────────────────

  /// Clear all data (for logout/reset).
  Future<void> clearAll() async {
    await isar.writeTxn(() async {
      await isar.pantryItems.clear();
      await isar.wasteLogs.clear();
      await isar.products.clear();
    });
  }
}
