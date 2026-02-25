import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a 408 Connection Timeout HTTP error occurs.
class ConnectionTimeoutException extends NetCoreException {
  /// Creates a [ConnectionTimeoutException with the given details.
  ConnectionTimeoutException({
    required super.requestConfig,
    int? statusCode,
    super.message = 'Connection Timeout',
    super.rawData,
    super.stackTrace,
  }) : super(
         statusCode: statusCode ?? 408,
       );
}
