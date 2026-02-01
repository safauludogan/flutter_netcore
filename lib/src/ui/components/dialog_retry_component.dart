import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_netcore/flutter_netcore.dart';

/// Implementation of [NetworkRetryComponent] using a dialog.
class DialogRetryComponent extends NetworkRetryComponent {
  DialogRetryComponent({
    required super.context,
    super.messageBuilder,
    super.maxManualRetries,
    this.titleBuilder,
    this.retryButtonText = 'Retry',
    this.cancelButtonText = 'Cancel',
  });

  /// Optional function to build the dialog title from the exception.
  final String Function(Exception)? titleBuilder;

  /// Text for the retry button.
  final String retryButtonText;

  /// Text for the cancel button.
  final String cancelButtonText;

  @override
  Future<RetryDecision> show({
    required NetCoreException error,
  }) async {
    final title = titleBuilder?.call(error) ?? 'Network Error';
    final message =
        messageBuilder?.call(error) ??
        'A network error occurred. Would you like to retry?';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelButtonText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(retryButtonText),
          ),
        ],
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
