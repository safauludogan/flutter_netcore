import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_netcore/src/ui/components/network_retry_component.dart';

/// Implementation of [NetworkRetryComponent] using a dialog.
class DialogRetryComponent extends NetworkRetryComponent {
  DialogRetryComponent({
    required this.context,
    this.titleBuilder,
    this.messageBuilder,
    this.retryButtonText = 'Retry',
    this.cancelButtonText = 'Cancel',
  });

  /// The BuildContext to show the dialog in.
  final BuildContext context;

  /// Optional function to build the dialog title from the exception.
  final String Function(Exception)? titleBuilder;

  /// Optional function to build the dialog message from the exception.
  final String Function(Exception)? messageBuilder;

  /// Text for the retry button.
  final String retryButtonText;

  /// Text for the cancel button.
  final String cancelButtonText;

  @override
  void show({
    required Exception error,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    final title = titleBuilder?.call(error) ?? 'Network Error';
    final message =
        messageBuilder?.call(error) ??
        'A network error occurred. Would you like to retry?';

    unawaited(
      showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel();
              },
              child: Text(cancelButtonText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(retryButtonText),
            ),
          ],
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
