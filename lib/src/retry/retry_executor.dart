import 'package:flutter_netcore/src/retry/retry_decider.dart';
import 'package:flutter_netcore/src/retry/retry_policy.dart';
import 'package:retry/retry.dart';

/// Executes operations with retry logic based on the provided [RetryPolicy] and [RetryDecider].
class RetryExecutor {
  /// Creates a [RetryExecutor] with the given [policy] and optional [retryIf] decider.
  RetryExecutor({
    required this.policy,
    RetryDecider? retryIf,
  }) : retryIf = retryIf ?? DefaultRetryDecider.shouldRetry;

  /// The retry policy defining the parameters for retries.
  final RetryPolicy policy;

  /// The function that decides whether to retry based on the encountered error.
  final RetryDecider retryIf;

  /// Executes the given [action] with retry logic.
  Future<T> execute<T>(Future<T> Function() action) {
    return retry(
      action,
      maxAttempts: policy.maxAttempts,
      delayFactor: policy.delay,
      retryIf: retryIf,
    );
  }
}
