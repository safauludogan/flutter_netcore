import 'package:flutter_netcore/flutter_netcore.dart';

/// Netcore logger
abstract class ILogger {
  /// logger
  void log(String message, {LogLevel level = LogLevel.info});

  /// Log request
  void logRequest<TReq>({
    required NetworkRequest request,
    required NetworkConfig config,
    TReq? body,
  });

  /// Log response
  void logResponse({
    required NetworkRequest request,
    required NetworkConfig config,
    required RawNetworkResponse response,
  });

  /// Log error
  void logError(NetCoreException exception);
}

/// LogLevel
enum LogLevel {
  /// Log debug
  debug,

  /// Log info
  info,

  /// Log warning
  warning,

  /// Log error
  error,
}
