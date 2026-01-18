import 'package:flutter/material.dart';
import 'package:flutter_netcore/src/ui/components/network_retry_component.dart';

/// Default implementation of [NetworkRetryComponent] using SnackBar.
class SnackbarRetryComponent extends NetworkRetryComponent {
  SnackbarRetryComponent({
    required this.context,
    required this.duration,
    required this.messageBuilder,
  });

  /// The BuildContext to show the SnackBar in.
  final BuildContext context;

  /// Duration for which the SnackBar is displayed.
  final Duration duration;

  /// Function to build the error message from the exception.
  final String Function(Exception)? messageBuilder;

  @override
  void show({
    required Exception error,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    final message =
        messageBuilder?.call(error) ??
        'Network error occurred. Please try again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            hide();
            onRetry();
          },
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void hide() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
