import 'package:flutter/material.dart';

class SyncStatusManager extends ValueNotifier<String> {
  SyncStatusManager() : super("Synced"); // Default status

  void updateStatus(String newStatus) {
    value = newStatus; // Update the value, which will notify listeners
  }
}

// Singleton instance
final syncStatusManager = SyncStatusManager();
