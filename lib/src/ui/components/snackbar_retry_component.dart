import 'package:flutter/material.dart';
import 'package:flutter_netcore/flutter_netcore.dart';

/// Default implementation of [NetworkRetryComponent] using SnackBar.
class SnackbarRetryComponent extends NetworkRetryComponent {
  SnackbarRetryComponent({
    required super.context,
    super.messageBuilder,
    super.maxManualRetries,
    this.retry = 'Retry',
    this.duration,
  });

  /// Duration for which the SnackBar is displayed.
  final Duration? duration;

  /// Label for the retry action.
  final String retry;
  @override
  Future<RetryDecision> show({
    required NetCoreException error,
  }) {
    final message =
        messageBuilder?.call(error) ??
        'Network error occurred. Please try again.';

    var retryIf = false;

    final snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
      duration: duration ?? const Duration(seconds: 4),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: retry,
        textColor: Colors.white,
        onPressed: () {
          retryIf = true;
          hide();
        },
      ),
      behavior: SnackBarBehavior.floating,
    );

    final controller = ScaffoldMessenger.of(context).showSnackBar(
      snackBar,
      snackBarAnimationStyle: const AnimationStyle(
        curve: Curves.easeInOut,
        reverseCurve: Curves.easeInOut,
      ),
    );

    return controller.closed.then((reason) {
      return retryIf ? RetryDecision.retry : RetryDecision.cancel;
    });
  }

  @override
  void hide() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
