import 'dart:async';

import 'package:flutter_netcore/src/exception/index.dart';

/// A function type that determines whether a retry should be attempted based on the provided error.
typedef RetryDecider = bool Function(Exception error);

/// A default implementation of [RetryDecider] that retries on network-related exceptions.
class DefaultRetryDecider {
  /// Determines whether a retry should be attempted based on the provided [error].
  static bool shouldRetry(Exception error) {
    if (error is NetCoreException) return true;
    if (error is TimeoutException) return true;

    // HTTP 5xx
    if (error is HttpException) {
      final code = error.statusCode ?? 0;
      return code >= 500;
    }

    return false;
  }
}
