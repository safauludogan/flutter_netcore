import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_netcore/src/ui/components/network_retry_component.dart';

/// Bottom sheet-based retry component with more details
class BottomSheetRetryComponent extends NetworkRetryComponent {
  BottomSheetRetryComponent({
    required this.context,
    this.titleBuilder,
    this.messageBuilder,
    this.detailsBuilder,
  });

  /// The BuildContext to show the bottom sheet in.
  final BuildContext context;

  /// Optional function to build the dialog title from the exception.
  final String Function(Exception)? titleBuilder;

  /// Optional function to build the dialog message from the exception.
  final String Function(Exception)? messageBuilder;

  /// Optional function to build additional details widget from the exception.
  final Widget Function(Exception)? detailsBuilder;

  @override
  void show({
    required Exception error,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    final title = titleBuilder?.call(error) ?? 'Network Error';
    final message =
        messageBuilder?.call(error) ?? 'Failed to connect to server';

    unawaited(
      showModalBottomSheet<dynamic>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24.0),
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
                      onPressed: () {
                        Navigator.of(context).pop();
                        onCancel();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onRetry();
                      },
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void hide() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
