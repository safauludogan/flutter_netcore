import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a Bad Response HTTP error occurs.
class BadResponseException extends NetCoreException {
  /// Creates a [BadResponseException] with the given details.
  BadResponseException({
      required super.requestConfig,
    super.message = 'Bad Response',
    super.rawData,
    super.stackTrace,
    super.statusCode,
  });
}
