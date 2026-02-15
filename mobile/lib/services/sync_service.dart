import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import 'api_client.dart';
import 'database_service.dart';

/// Background sync service that periodically sends unsynced items to the server.
class SyncService {
  final DatabaseService _db = DatabaseService();
  final ApiClient _apiClient = ApiClient();
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Start periodic background sync.
  void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(minutes: AppConstants.syncIntervalMinutes),
      (_) => syncUnsyncedItems(),
    );
  }

  /// Stop periodic sync.
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Schedule an immediate sync attempt.
  void scheduleSync() {
    // Debounce: don't sync if already syncing
    if (!_isSyncing) {
      syncUnsyncedItems();
    }
  }

  /// Sync all unsynced items to the backend.
  Future<void> syncUnsyncedItems() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final unsynced = await _db.getUnsyncedItems();
      if (unsynced.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint('SyncService: Syncing ${unsynced.length} items...');

      final response = await _apiClient.syncItems(
        unsynced.map((item) => item.toJson()).toList(),
      );

      if (response.statusCode == 200) {
        await _db.markItemsSynced(unsynced);
        debugPrint('SyncService: Successfully synced ${unsynced.length} items');
      }
    } catch (e) {
      debugPrint('SyncService: Sync failed — $e');
      // Retry on next sync cycle
    } finally {
      _isSyncing = false;
    }
  }

  /// Dispose the sync service.
  void dispose() {
    stopPeriodicSync();
  }
}
