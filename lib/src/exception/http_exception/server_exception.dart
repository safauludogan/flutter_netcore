import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a 500 Server Error HTTP error occurs.
class ServerException extends NetCoreException {
  /// Creates a [ServerException] with the given details.
  ServerException({
    required super.requestConfig,
    super.message = 'Server Error',
    super.statusCode,
    super.rawData,
    super.stackTrace,
  });
}
