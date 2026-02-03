import 'dart:async';

import 'package:flutter_netcore/flutter_netcore.dart';

/// Mixin to handle network errors with optional retry mechanisms.
mixin NetworkErrorHandler {
  /// Handles network errors and applies retry logic if specified.
  Future<TRes> handleWithRetry<TRes>({
    required Future<TRes> Function() action,
    NetworkRetry? networkRetry,
    ILogger? logger,
  }) async {
    /// If no retry configuration is provided, execute the action directly.
    logger?.log(
      '🚀 Network action started',
      level: LogLevel.debug,
    );

    if (networkRetry == null) {
      try {
        return await action();
      } catch (e) {
        logger?.log(
          '❌ Network action failed (no retry)',
          level: LogLevel.error,
        );
        rethrow;
      }
    }

    var manualRetryCount = 0;

    final retryExecutor = RetryExecutor(
      policy: networkRetry.policy ?? const RetryPolicy(),
      retryIf: networkRetry.retryIf,
    );

    while (true) {
      try {
        final result = await retryExecutor.execute(action);

        logger?.log(
          '✅ Network action succeeded',
          level: LogLevel.debug,
        );

        return result;
      } on NetCoreException catch (error) {
        /// If manual retry is needed, invoke the callback if provided.

        logger?.log(
          '🔁 Network error caught: $error',
          level: LogLevel.warning,
        );

        if (manualRetryCount >=
            (networkRetry.component?.maxManualRetries ?? 0)) {
          logger?.log(
            '❌ Retry aborted (manual retry disabled or limit reached)',
            level: LogLevel.error,
          );
          rethrow;
        }

        manualRetryCount++;

        logger?.log(
          '''
          👆 Manual retry required
          ($manualRetryCount/${networkRetry.component?.maxManualRetries ?? 0})
          ''',
        );

        // Use component if provided
        if (networkRetry.component != null) {
          final shouldRetry = await _waitForManualRetry(
            component: networkRetry.component!,
            error: error,
            hideDuration: networkRetry.hideDuration,
            logger: logger,
          );

          if (!shouldRetry) {
            logger?.log(
              '👆 Waiting for deprecated manual retry callback',
            );
            rethrow;
          }

          // Continue to next iteration to retry
          continue;
        }

        logger?.log(
          '❌ No manual retry mechanism available',
          level: LogLevel.error,
        );

        // No retry mechanism available
        rethrow;
      } on Exception catch (e) {
        logger?.log(
          '❌ Network action failed with unexpected error: $e',
          level: LogLevel.error,
        );
        rethrow;
      }
    }
  }

  Future<bool> _waitForManualRetry({
    required NetworkRetryComponent component,
    required NetCoreException error,
    ILogger? logger,
    Duration? hideDuration,
  }) async {
    var completed = false;

    final completer = Completer<bool>();

    Timer? timer;
    if (hideDuration != null) {
      timer = Timer(hideDuration, () {
        if (completed) return;
        completed = true;
        component.hide();
        completer.complete(false);
      });
    }

    await component.show(error: error).then((decision) {
      decision == RetryDecision.retry
          ? logger?.log(
              '🔄 User triggered manual retry',
            )
          : logger?.log(
              '⛔ User cancelled manual retry',
              level: LogLevel.warning,
            );

      if (completed) return;

      completed = true;
      timer?.cancel();

      completer.complete(decision == RetryDecision.retry);
    });

    return completer.future;
  }
}
