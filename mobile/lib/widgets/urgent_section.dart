import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import 'item_tile.dart';

/// Section widget displaying urgently expiring items (≤3 days).
class UrgentSection extends StatelessWidget {
  final List<PantryItem> items;
  final void Function(PantryItem item)? onItemTap;

  const UrgentSection({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Expiring Soon (${items.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => ItemTile(
              item: item,
              onTap: onItemTap != null ? () => onItemTap!(item) : null,
            )),
        const Divider(height: 32),
      ],
    );
  }
}

/// Section widget displaying warning items (4-7 days).
class WarningSection extends StatelessWidget {
  final List<PantryItem> items;
  final void Function(PantryItem item)? onItemTap;

  const WarningSection({
    super.key,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange[700], size: 24),
              const SizedBox(width: 8),
              Text(
                'Use Soon (${items.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => ItemTile(
              item: item,
              onTap: onItemTap != null ? () => onItemTap!(item) : null,
            )),
        const Divider(height: 32),
      ],
    );
  }
}
