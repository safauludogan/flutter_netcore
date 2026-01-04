import 'package:flutter/foundation.dart';
import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a parsing error occurs.
/// Extends [NetCoreException] to provide parsing-specific error handling.
/// Includes details such as,
/// [message], [statusCode], [rawError], and [stackTrace].

@immutable
class ParsingException extends NetCoreException {
  /// Creates a [ParsingException] with the given details.
  ParsingException({
    required super.message,
    super.statusCode,
    super.rawData,
    super.stackTrace,
  });
}
