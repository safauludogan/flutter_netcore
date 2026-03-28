import 'dart:async';

import 'package:flutter_netcore/src/core/http_method.dart';
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
      // Parse errors are client-side logic errors, not transient — retrying
      // the same request will never fix a broken model mapping.
      if (error is ParsingException) return false;

      final code = error.statusCode;

      // No HTTP status code -> likely network/timeout/unknown -> retry
      if (code == null) return true;

      // Non-idempotent methods (POST, PATCH, DELETE) must NOT be retried on
      // 5xx because the server may have already processed the request
      // (e.g. user created successfully but server returned 500 for another
      // reason — retrying would cause "user already exists").
      final method = error.requestConfig?.method;
      if (method == HttpMethod.post || method == HttpMethod.patch || method == HttpMethod.delete) {
        return false;
      }

      // Retry only on 5xx server errors for idempotent methods (GET, PUT, HEAD)
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
