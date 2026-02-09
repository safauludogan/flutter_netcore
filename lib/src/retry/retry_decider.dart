import 'dart:async';

import 'package:flutter_netcore/src/exception/index.dart';

/// A function type that determines whether a retry should be attempted based on the provided error.
typedef RetryDecider = bool Function(Exception error);

/// A default implementation of [RetryDecider] that retries on network-related exceptions.
class DefaultRetryDecider {
  /// Determines whether a retry should be attempted based on the provided [error].
  static bool shouldRetry(Exception error) {
    // If it's a NetCoreException, only retry for transient errors
    // (no status code / network errors) or server errors (5xx).
    if (error is NetCoreException) {
      final code = error.statusCode;

      // No HTTP status code -> likely network/timeout/unknown -> retry
      if (code == null) return true;

      // Retry only on 5xx server errors
      return code >= 500;
    }

    if (error is TimeoutException) return true;

    // HTTP wrapper: retry on 5xx only
    if (error is HttpException) {
      final code = error.statusCode ?? 0;
      return code >= 500;
    }

    return false;
  }
}
