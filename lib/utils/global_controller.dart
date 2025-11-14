import 'package:flutter/material.dart';

/// Remove the shared notifier - use map only
Map<String, ValueNotifier<int>> brightnessNotifiers = {};

/// Prevent self-trigger loop when receiving external MQTT updates
bool internalUpdate = false;

/// Optional: Refresh notifier to reload device UI if needed
final ValueNotifier<bool> deviceRefreshNotifier = ValueNotifier(false);

final ValueNotifier<String> usernameNotifier = ValueNotifier<String>('');
