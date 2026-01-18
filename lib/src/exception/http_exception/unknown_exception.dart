import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a Receive Timeout HTTP error occurs.
class UnknownException extends NetCoreException {
  /// Creates a [UnknownException] with the given details.
  UnknownException({
    required super.requestConfig,
    super.message = 'Unknown',
    super.rawData,
    super.stackTrace,
        super.statusCode,
  });
}
