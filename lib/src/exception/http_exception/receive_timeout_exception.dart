import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a 408 Receive Timeout HTTP error occurs.
class ReceiveTimeoutException extends NetCoreException {
  /// Creates a [ReceiveTimeoutException] with the given details.
  ReceiveTimeoutException({
      required super.requestConfig,
    super.message = 'Receive Timeout',
    super.rawData,
    super.stackTrace,
  }) : super(
         statusCode: 408,
       );
}
