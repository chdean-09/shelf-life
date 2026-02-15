import 'package:flutter/material.dart';
import '../models/pantry_item.dart';
import '../utils/constants.dart';

/// A single pantry item tile with expiry color coding.
class ItemTile extends StatelessWidget {
  final PantryItem item;
  final VoidCallback? onTap;

  const ItemTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.daysUntilExpiry;

    return Card(
      color: _getBackgroundColor(daysLeft),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight:
                daysLeft <= AppConstants.urgentDays ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          _getSubtitleText(daysLeft),
          style: TextStyle(
            color: daysLeft <= 0 ? Colors.red[800] : null,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStorageIcon(item.storageLocation),
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              item.storageLocation.name,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getBackgroundColor(int daysLeft) {
    if (daysLeft <= 0) return Colors.red[100]!;
    if (daysLeft <= AppConstants.urgentDays) return Colors.red[50]!;
    if (daysLeft <= AppConstants.warningDays) return Colors.orange[50]!;
    return Colors.white;
  }

  Widget _buildLeadingIcon() {
    final daysLeft = item.daysUntilExpiry;
    IconData icon;
    Color color;

    if (daysLeft <= 0) {
      icon = Icons.error;
      color = Colors.red;
    } else if (daysLeft <= AppConstants.urgentDays) {
      icon = Icons.warning;
      color = Colors.red;
    } else if (daysLeft <= AppConstants.warningDays) {
      icon = Icons.access_time;
      color = Colors.orange;
    } else {
      icon = Icons.check_circle;
      color = Colors.green;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color),
    );
  }

  String _getSubtitleText(int daysLeft) {
    if (daysLeft < 0) return 'Expired ${-daysLeft} day(s) ago';
    if (daysLeft == 0) return 'Expires today!';
    if (daysLeft == 1) return 'Expires tomorrow';
    return 'Expires in $daysLeft days';
  }

  IconData _getStorageIcon(StorageLocation location) {
    switch (location) {
      case StorageLocation.pantry:
        return Icons.kitchen;
      case StorageLocation.fridge:
        return Icons.ac_unit;
      case StorageLocation.freezer:
        return Icons.severe_cold;
    }
  }
}
