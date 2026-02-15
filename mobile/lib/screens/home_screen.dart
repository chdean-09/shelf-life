import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../widgets/item_tile.dart';
import '../widgets/urgent_section.dart';
import 'add_item_screen.dart';
import 'scanner_screen.dart';
import 'stats_screen.dart';

/// Main home screen with expiration-first dashboard.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(pantryProvider);
    final urgentItems = ref.watch(urgentItemsProvider);
    final warningItems = ref.watch(warningItemsProvider);
    final expiredItems = ref.watch(expiredItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShelfLife'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.kitchen, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Your pantry is empty!',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add your first item',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Build the safe items list (> 7 days)
          final safeItems = items.where((item) {
            final days = item.daysUntilExpiry;
            return days > 7 && !item.isExpired;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.read(pantryProvider.notifier).loadItems();
            },
            child: ListView(
              children: [
                // Summary bar
                _buildSummaryBar(context, items.length, urgentItems.length,
                    expiredItems.length),

                // Expired items
                if (expiredItems.isNotEmpty)
                  UrgentSection(
                    items: expiredItems,
                    onItemTap: (item) =>
                        _showItemOptions(context, ref, item),
                  ),

                // Urgent items (≤3 days)
                if (urgentItems.isNotEmpty)
                  UrgentSection(
                    items: urgentItems,
                    onItemTap: (item) =>
                        _showItemOptions(context, ref, item),
                  ),

                // Warning items (4-7 days)
                if (warningItems.isNotEmpty)
                  WarningSection(
                    items: warningItems,
                    onItemTap: (item) =>
                        _showItemOptions(context, ref, item),
                  ),

                // Safe items
                if (safeItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'All Good (${safeItems.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...safeItems.map((item) => Dismissible(
                        key: Key(item.id.toString()),
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            return await _showWastePriceDialog(
                                context, ref, item);
                          } else {
                            ref
                                .read(pantryProvider.notifier)
                                .markAsConsumed(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('${item.name} marked as consumed')),
                            );
                            return true;
                          }
                        },
                        child: ItemTile(
                          item: item,
                          onTap: () =>
                              _showItemOptions(context, ref, item),
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'scan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScannerScreen()),
            ),
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddItemScreen()),
            ),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(
      BuildContext context, int total, int urgent, int expired) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total', total.toString(), Colors.blue),
          _summaryItem('Urgent', urgent.toString(), Colors.red),
          _summaryItem('Expired', expired.toString(), Colors.grey),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showItemOptions(
      BuildContext context, WidgetRef ref, PantryItem item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Item'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddItemScreen(editItem: item),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark as Consumed'),
              onTap: () {
                ref.read(pantryProvider.notifier).markAsConsumed(item);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} marked as consumed')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Mark as Wasted'),
              onTap: () {
                Navigator.pop(ctx);
                _showWastePriceDialog(context, ref, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.grey),
              title: const Text('Delete'),
              onTap: () {
                ref.read(pantryProvider.notifier).deleteItem(item.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showWastePriceDialog(
      BuildContext context, WidgetRef ref, PantryItem item) async {
    final priceController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Waste'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How much did "${item.name}" cost?'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '\$ ',
                labelText: 'Estimated Price',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final price =
                  double.tryParse(priceController.text) ?? 0.0;
              ref
                  .read(pantryProvider.notifier)
                  .markAsWasted(item, price);
              Navigator.pop(ctx, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} logged as waste')),
              );
            },
            child: const Text('Log Waste'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
