import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a Connection Error HTTP error occurs.
class ConnectionErrorException extends NetCoreException {
  /// Creates a [ConnectionErrorException] with the given details.
  ConnectionErrorException({
      required super.requestConfig,
    super.message = 'Connection Error',
    super.rawData,
    super.stackTrace,
        super.statusCode,
  });
}
