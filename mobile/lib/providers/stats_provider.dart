import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pantry_provider.dart';

/// Provider for monthly waste total.
final monthlyWasteTotalProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return await db.getMonthlyWasteTotal();
});

/// Provider for waste breakdown by category.
final wasteByCategeryProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  return await db.getMonthlyWasteByCategory();
});

/// Provider for total items count.
final totalItemsCountProvider = Provider<int>((ref) {
  final itemsAsync = ref.watch(pantryProvider);
  return itemsAsync.when(
    data: (items) => items.length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

/// Provider for expiring-soon count.
final expiringSoonCountProvider = Provider<int>((ref) {
  final urgentItems = ref.watch(urgentItemsProvider);
  return urgentItems.length;
});
