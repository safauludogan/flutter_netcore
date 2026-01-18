import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a Bad Request HTTP error occurs.
class BadRequestException extends NetCoreException {
  /// Creates a [BadRequestException] with the given details.
  BadRequestException({
    required super.requestConfig,
    super.message = 'Bad Request',
    super.rawData,
    super.stackTrace,
    super.statusCode,
  });
}
