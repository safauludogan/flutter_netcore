import 'package:flutter/material.dart';
import 'package:flutter_netcore/flutter_netcore.dart';

/// Abstract base class for retry UI components.
abstract class NetworkRetryComponent {
  NetworkRetryComponent({
    required this.context,
    this.messageBuilder,
    this.maxManualRetries = 3,
  });

  /// Build context for displaying UI elements.
  final BuildContext context;

  /// Optional function to build the dialog message from the exception.
  final String Function(NetCoreException)? messageBuilder;

  /// Maximum number of manual retries allowed.
  int? maxManualRetries = 3;

  /// Displays the retry UI component.
  Future<RetryDecision> show({
    required NetCoreException error,
  });

  /// Hides the retry UI component.
  void hide();
}
