import 'package:flutter/material.dart';

/// Abstract base class for retry UI components.
abstract class NetworkRetryComponent {
  /// Displays the retry UI component.
  void show({
    required Exception error,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  });

  /// Hides the retry UI component.
  void hide();
}
