import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a parsing error occurs.
/// Extends [NetCoreException] to provide parsing-specific error handling.
/// Includes details such as,
/// [message], [statusCode], [rawData], [requestConfig] and [stackTrace].

class AdapterException extends NetCoreException {
  /// Creates a [AdapterException] with the given details.
  AdapterException({
    required super.message,
    super.requestConfig,
    super.rawData,
    super.stackTrace,
  });
}
