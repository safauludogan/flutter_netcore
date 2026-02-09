import 'dart:async';

import 'package:flutter_netcore/flutter_netcore.dart';
import 'package:flutter_netcore/src/configuration/network_request_config.dart';
import 'package:flutter_netcore/src/mapper/netcore_error_mapper.dart';

/// Mixin to handle network errors with optional retry mechanisms.
mixin NetworkRetryHandlerMixin {
  /// Handles network errors and applies retry logic if specified.
  Future<TRes> handleWithRetry<TRes>({
    required Future<TRes> Function(NetworkRequestConfig? requestConfig) action,
    required NetworkRequestConfig requestConfig,
    NetworkRetry? networkRetry,
    ILogger? logger,
    RefreshTokenHandler? refreshTokenHandler,
    RefreshTokenFailHandler? refreshTokenFailHandler,
  }) async {
    var authRefreshAttempted = false;
    var manualRetryCount = 0;

    /// If no retry configuration is provided, execute the action directly.
    logger?.log(
      '🚀 Network action started',
      level: LogLevel.debug,
    );

    if (requestConfig.skipAuthHandling) {
      logger?.log(
        '🚪 Skipping auth & retry handling for this request',
        level: LogLevel.debug,
      );
      return action(requestConfig);
    }

    if (networkRetry == null) {
      try {
        return await action(requestConfig);
      } on Exception catch (e) {
        logger?.log(
          '❌ Network action failed (no retry)',
          level: LogLevel.error,
        );
        final netCoreException = NetCoreErrorMapper.map(
          e,
          requestConfig: requestConfig,
        );
        logger?.logError(netCoreException);
        if (netCoreException.statusCode != 401 || authRefreshAttempted) {
          rethrow;
        }

        authRefreshAttempted = true;
        final refreshedError = await refreshToken(
          refreshTokenHandler,
          netCoreException,
          logger,
        );
        // Update request with new token
        final newRequestConfig = refreshedError?.requestConfig ?? requestConfig;

        logger?.log(
          '✅ Token refresh succeeded, retrying request',
          level: LogLevel.debug,
        );
        return action(newRequestConfig);
      }
    }

    final retryExecutor = RetryExecutor(
      policy: networkRetry.policy ?? const RetryPolicy(),
      retryIf: (error) {
        // ✅ ENFORCE: Never auto-retry 401/403
        if (error is NetCoreException) {
          if (error.statusCode == 401 || error.statusCode == 403) {
            return false;
          }
        }

        // Then apply custom or default logic
        return networkRetry.retryIf?.call(error) ?? DefaultRetryDecider.shouldRetry(error);
      },
    );

    while (true) {
      try {
        final result = await retryExecutor.execute.call(
          () async => action.call(null),
        );

        logger?.log(
          '✅ Network action succeeded',
          level: LogLevel.debug,
        );

        return result;
      } on NetCoreException catch (error) {
        logger?.log(
          '🔁 Network error caught: $error',
          level: LogLevel.warning,
        );

        if (error.statusCode == 401 && !authRefreshAttempted) {
          authRefreshAttempted = true;

          logger?.log(
            '🔐 Attempting token refresh after 401',
            level: LogLevel.warning,
          );

          try {
            if (refreshTokenHandler == null) {
              logger?.log(
                '❌ No refreshTokenHandler provided',
                level: LogLevel.error,
              );
              rethrow;
            }
            final refreshedError = await refreshToken(refreshTokenHandler, error, logger);

            // Update request with new token
            final newRequestConfig = refreshedError?.requestConfig ?? requestConfig;

            logger?.log(
              '✅ Token refresh succeeded, retrying request',
              level: LogLevel.debug,
            );

            return await action(newRequestConfig);
          } on Exception catch (refreshError) {
            logger?.log(
              '❌ Token refresh failed',
              level: LogLevel.error,
            );

            try {
              // Call failure handler
              await refreshTokenFailHandler?.call(
                NetCoreErrorMapper.map(
                  refreshError,
                  requestConfig: requestConfig,
                ),
              );
            } on Exception catch (e) {
              final err = NetCoreErrorMapper.map(
                e,
                requestConfig: requestConfig,
              );
              if (err.statusCode == 401 || err.statusCode == 403) {
                rethrow;
              }
            }

            rethrow; // 401 is terminal after refresh fails
          }
        }

        if (!_shouldAllowManualRetry(error)) {
          logger?.log(
            '⛔ Manual retry blocked for statusCode=${error.statusCode}',
            level: LogLevel.warning,
          );
          rethrow;
        }

        if (manualRetryCount >= (networkRetry.component?.maxManualRetries ?? 0)) {
          logger?.log(
            '❌ Max manual retries reached',
            level: LogLevel.error,
          );
          rethrow;
        }

        manualRetryCount++;

        final logTryCount = networkRetry.component?.maxManualRetries ?? 0;
        logger?.log(
          '($manualRetryCount/$logTryCount) 👆 Manual retry required',
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
      } on Exception catch (error) {
        logger?.log(
          '❌ Network action failed with unexpected error: $error',
          level: LogLevel.error,
        );
        final netCoreException = NetCoreErrorMapper.map(
          error,
          requestConfig: requestConfig,
        );
        logger?.logError(netCoreException);
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

  bool _shouldAllowManualRetry(NetCoreException e) {
    final code = e.statusCode;
    if (code == 401 || code == 403) return false;
    if (code == null) return true; // network error
    return code >= 500;
  }

  /// Refresh manager
  Future<NetCoreException?> refreshToken(
    RefreshTokenHandler? refreshTokenHandler,
    NetCoreException exception,
    ILogger? logger,
  ) async {
    if (refreshTokenHandler == null) {
      logger?.log(
        '❌ No refreshTokenHandler provided',
        level: LogLevel.error,
      );
      return exception;
    }
    return refreshTokenHandler.call(exception);
  }
}
