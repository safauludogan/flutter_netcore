import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a Socket Exception HTTP error occurs.
class SocketException extends NetCoreException {
  /// Creates a [SocketException] with the given details.
  SocketException({
    required super.requestConfig,
    super.message = 'Socket Exception',
    super.rawData,
    super.stackTrace,
    super.statusCode
  });
}
