// ignore_for_file: sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_netcore/src/retry/retry_policy.dart';
import 'package:flutter_netcore/src/ui/components/index.dart';

/// Class representing a network retry mechanism.
class NetworkRetry {
  NetworkRetry({
    this.policy,
    this.retryIf,
    this.maxManualRetries = 3,
    this.component,
    this.enableManualRetry = true,
    this.onManualRetryNeeded,
  });

  /// The retry component to use for showing retry UI
  final NetworkRetryComponent? component;

  /// Whether to enable manual retry
  final bool enableManualRetry;

  /// The retry policy defining the conditions and limits for retries.
  final RetryPolicy? policy;

  /// Condition to determine if retry should be attempted
  final bool Function(Exception)? retryIf;

  /// Maximum number of manual retries allowed.
  final int maxManualRetries;

  /// Callback invoked when a manual retry is needed.
  final void Function(
    Exception error,
    Future<void> Function() retryAction,
  )?
  onManualRetryNeeded;

  /// Creates a NetworkRetry with SnackBar component
  factory NetworkRetry.snackBar({
    required BuildContext context,
    int maxManualRetries = 3,
    RetryPolicy? policy,
    bool Function(Exception)? retryIf,
    String Function(Exception)? messageBuilder,
    Duration duration = const Duration(seconds: 5),
  }) {
    return NetworkRetry(
      component: SnackbarRetryComponent(
        context: context,
        messageBuilder: messageBuilder,
        duration: duration,
      ),
      maxManualRetries: maxManualRetries,
      policy: policy,
      retryIf: retryIf,
    );
  }

  /// Creates a NetworkRetry with Dialog component
  factory NetworkRetry.dialog({
    required BuildContext context,
    int maxManualRetries = 3,
    RetryPolicy? policy,
    bool Function(Exception)? retryIf,
    String Function(Exception)? titleBuilder,
    String Function(Exception)? messageBuilder,
    String retryButtonText = 'Retry',
    String cancelButtonText = 'Cancel',
  }) {
    return NetworkRetry(
      component: DialogRetryComponent(
        context: context,
        titleBuilder: titleBuilder,
        messageBuilder: messageBuilder,
        retryButtonText: retryButtonText,
        cancelButtonText: cancelButtonText,
      ),
      maxManualRetries: maxManualRetries,
      policy: policy,
      retryIf: retryIf,
    );
  }

  /// Creates a NetworkRetry with BottomSheet component
  factory NetworkRetry.bottomSheet({
    required BuildContext context,
    int maxManualRetries = 3,
    RetryPolicy? policy,
    bool Function(Exception)? retryIf,
    String Function(Exception)? titleBuilder,
    String Function(Exception)? messageBuilder,
    Widget Function(Exception)? detailsBuilder,
  }) {
    return NetworkRetry(
      component: BottomSheetRetryComponent(
        context: context,
        titleBuilder: titleBuilder,
        messageBuilder: messageBuilder,
        detailsBuilder: detailsBuilder,
      ),
      maxManualRetries: maxManualRetries,
      policy: policy,
      retryIf: retryIf,
    );
  }

  /// Creates a NetworkRetry with custom component
  factory NetworkRetry.custom({
    required NetworkRetryComponent component,
    int maxManualRetries = 3,
    RetryPolicy? policy,
    bool Function(Exception)? retryIf,
  }) {
    return NetworkRetry(
      component: component,
      maxManualRetries: maxManualRetries,
      policy: policy,
      retryIf: retryIf,
    );
  }

  /// Creates a NetworkRetry without UI (only automatic retries)
  factory NetworkRetry.autoOnly({
    required RetryPolicy policy,
    bool Function(Exception)? retryIf,
  }) {
    return NetworkRetry(
      enableManualRetry: false,
      policy: policy,
      retryIf: retryIf,
    );
  }
}
