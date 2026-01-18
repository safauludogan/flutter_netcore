import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a 408 Send Timeout HTTP error occurs.
class SendTimeoutException extends NetCoreException {
  /// Creates a [SendTimeoutException] with the given details.
  SendTimeoutException({
    required super.requestConfig,
    super.message = 'Send Timeout',
    super.rawData,
    super.stackTrace,
  }) : super(
         statusCode: 408,
       );
}
