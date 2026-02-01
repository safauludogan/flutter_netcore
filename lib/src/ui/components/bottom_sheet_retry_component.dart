import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_netcore/flutter_netcore.dart';

/// Bottom sheet-based retry component with more details
class BottomSheetRetryComponent extends NetworkRetryComponent {
  BottomSheetRetryComponent({
    required super.context,
    super.messageBuilder,
    super.maxManualRetries,
    this.retry = 'Retry',
    this.cancel = 'Cancel',
    this.titleBuilder,
    this.detailsBuilder,
  });

  /// Optional function to build the dialog title from the exception.
  final String Function(NetCoreException)? titleBuilder;

  /// Optional function to build additional details widget from the exception.
  final Widget Function(NetCoreException)? detailsBuilder;

  /// Label for the retry action.
  final String retry;

  /// Label for the cancel action.
  final String cancel;

  @override
  Future<RetryDecision> show({
    required NetCoreException error,
  }) async {
    final title = titleBuilder?.call(error) ?? 'Network Error';
    final message =
        messageBuilder?.call(error) ?? 'Failed to connect to server';

    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(message),
            if (detailsBuilder != null) ...[
              const SizedBox(height: 12),
              detailsBuilder!(error),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(retry),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return (result ?? false) ? RetryDecision.retry : RetryDecision.cancel;
  }

  @override
  void hide() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
