import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a Conflict HTTP error occurs.
class ConflictException extends NetCoreException {
  /// Creates a [ConflictException] with the given details.
  ConflictException({
    required super.requestConfig,
    super.message = 'Conflict',
    super.rawData,
    super.stackTrace,
    super.statusCode,
  });
}
