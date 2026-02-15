import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pantry_item.dart';
import '../models/waste_log.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

/// Provider for the database service instance.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Provider for the sync service instance.
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

/// State notifier for pantry items.
class PantryNotifier extends StateNotifier<AsyncValue<List<PantryItem>>> {
  final DatabaseService _db;
  final SyncService _syncService;

  PantryNotifier(this._db, this._syncService)
      : super(const AsyncValue.loading()) {
    loadItems();
  }

  /// Load all items from the local database.
  Future<void> loadItems() async {
    try {
      state = const AsyncValue.loading();
      final items = await _db.getAllItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add a new pantry item.
  Future<void> addItem(PantryItem item) async {
    await _db.addItem(item);
    _syncService.scheduleSync();
    await loadItems();
  }

  /// Update an existing pantry item.
  Future<void> updateItem(PantryItem item) async {
    await _db.updateItem(item);
    _syncService.scheduleSync();
    await loadItems();
  }

  /// Delete a pantry item.
  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    await loadItems();
  }

  /// Mark an item as consumed (delete it).
  Future<void> markAsConsumed(PantryItem item) async {
    await _db.deleteItem(item.id);
    await loadItems();
  }

  /// Mark an item as wasted — delete it and add to waste log.
  Future<void> markAsWasted(PantryItem item, double estimatedPrice) async {
    final wasteLog = WasteLog(
      itemName: item.name,
      category: item.category ?? 'other',
      estimatedPrice: estimatedPrice,
    );
    await _db.addWasteLog(wasteLog);
    await _db.deleteItem(item.id);
    await loadItems();
  }
}

/// Provider for the pantry items state notifier.
final pantryProvider =
    StateNotifierProvider<PantryNotifier, AsyncValue<List<PantryItem>>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  final sync = ref.watch(syncServiceProvider);
  return PantryNotifier(db, sync);
});

/// Provider that filters items expiring within 3 days (urgent).
final urgentItemsProvider = Provider<List<PantryItem>>((ref) {
  final itemsAsync = ref.watch(pantryProvider);
  return itemsAsync.when(
    data: (items) => items.where((item) => item.isExpiringSoon(3)).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Provider that filters items expiring within 4-7 days (warning).
final warningItemsProvider = Provider<List<PantryItem>>((ref) {
  final itemsAsync = ref.watch(pantryProvider);
  return itemsAsync.when(
    data: (items) => items.where((item) {
      final days = item.daysUntilExpiry;
      return days > 3 && days <= 7;
    }).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

/// Provider for expired items.
final expiredItemsProvider = Provider<List<PantryItem>>((ref) {
  final itemsAsync = ref.watch(pantryProvider);
  return itemsAsync.when(
    data: (items) => items.where((item) => item.isExpired).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});
