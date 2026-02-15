import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A pie chart widget showing waste breakdown by category.
class WasteChart extends StatelessWidget {
  final Map<String, double> wasteByCategory;

  const WasteChart({
    super.key,
    required this.wasteByCategory,
  });

  static const List<Color> _categoryColors = [
    Colors.red,
    Colors.orange,
    Colors.amber,
    Colors.green,
    Colors.teal,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    if (wasteByCategory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No waste data yet.\nSwipe left on items to log waste.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: _buildSections(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    final entries = wasteByCategory.entries.toList();
    final total = wasteByCategory.values.fold(0.0, (a, b) => a + b);

    return entries.asMap().entries.map((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;
      final percentage = (entry.value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        value: entry.value,
        title: '$percentage%',
        color: _categoryColors[index % _categoryColors.length],
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final entries = wasteByCategory.entries.toList();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: entries.asMap().entries.map((mapEntry) {
        final index = mapEntry.key;
        final entry = mapEntry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _categoryColors[index % _categoryColors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.key}: \$${entry.value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        );
      }).toList(),
    );
  }
}
