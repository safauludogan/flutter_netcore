import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// General HTTP exception class.
/// Can be used for various HTTP error scenarios.
/// Extends [NetCoreException] to provide HTTP-specific error handling.
/// Includes optional [statusCode] for HTTP status representation.
class HttpException extends NetCoreException {
  /// Creates a [HttpException] with the given details.
  HttpException({
    required super.requestConfig,
    required super.message,
    super.statusCode,
    super.rawData,
    super.stackTrace,
  });
}
