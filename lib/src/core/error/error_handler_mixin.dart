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
      } on Exception catch (error) {
        /// If manual retry is needed, invoke the callback if provided.

        logger?.log(
          '🔁 Network error caught: $error',
          level: LogLevel.warning,
        );

        if (!networkRetry.enableManualRetry ||
            manualRetryCount >= networkRetry.maxManualRetries) {
          logger?.log(
            '❌ Retry aborted (manual retry disabled or limit reached)',
            level: LogLevel.error,
          );
          rethrow;
        }

        manualRetryCount++;

        logger?.log(
          '👆 Manual retry required ($manualRetryCount/${networkRetry.maxManualRetries})',
        );

        // Use component if provided
        if (networkRetry.component != null) {
          final completer = Completer<bool>();

          networkRetry.component!.show(
            error: error,
            onRetry: () {
              logger?.log(
                '🔄 User triggered manual retry',
              );

              if (!completer.isCompleted) {
                completer.complete(true);
              }
            },
            onCancel: () {
              logger?.log(
                '⛔ User cancelled manual retry',
                level: LogLevel.warning,
              );

              if (!completer.isCompleted) {
                completer.complete(false);
              }
            },
          );

          final shouldRetry = await completer.future;

          if (!shouldRetry) {
            logger?.log(
              '👆 Waiting for deprecated manual retry callback',
            );
            rethrow;
          }

          // Continue to next iteration to retry
          continue;
        }

        // Fallback to deprecated callback
        if (networkRetry.onManualRetryNeeded != null) {
          final completer = Completer<void>();

          networkRetry.onManualRetryNeeded!(error, () async {
            logger?.log(
              '🔄 Deprecated manual retry triggered',
            );

            if (!completer.isCompleted) {
              completer.complete();
            }
          });

          await completer.future;
          continue;
        }

        logger?.log(
          '❌ No manual retry mechanism available',
          level: LogLevel.error,
        );

        // No retry mechanism available
        rethrow;
      }
    }
  }
}
