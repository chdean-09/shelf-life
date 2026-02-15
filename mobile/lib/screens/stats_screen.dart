import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';
import '../widgets/waste_chart.dart';

/// Statistics screen showing waste tracking data.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyTotal = ref.watch(monthlyWasteTotalProvider);
    final wasteByCategory = ref.watch(wasteByCategeryProvider);
    final totalItems = ref.watch(totalItemsCountProvider);
    final expiringSoon = ref.watch(expiringSoonCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Items',
                    value: totalItems.toString(),
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Expiring Soon',
                    value: expiringSoon.toString(),
                    icon: Icons.warning_amber,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Monthly waste card
            monthlyTotal.when(
              data: (total) => _StatCard(
                title: 'Waste This Month',
                value: '\$${total.toStringAsFixed(2)}',
                icon: Icons.money_off,
                color: Colors.red,
                fullWidth: true,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 24),

            // Chart title
            Text(
              'Waste by Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Pie chart
            wasteByCategory.when(
              data: (data) => WasteChart(wasteByCategory: data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),

            const SizedBox(height: 24),

            // Tips section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb,
                            color: Colors.amber[700], size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Tips to Reduce Waste',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _tipItem('Plan meals before shopping'),
                    _tipItem('Store items at proper temperatures'),
                    _tipItem('Use the FIFO method (First In, First Out)'),
                    _tipItem('Freeze items before they expire'),
                    _tipItem('Check your pantry before shopping'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('  •  ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: fullWidth
            ? Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13)),
                      Text(value,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(value,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(title,
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
      ),
    );
  }
}
