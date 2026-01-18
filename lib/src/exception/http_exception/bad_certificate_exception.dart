import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a Bad Certificate HTTP error occurs.
class BadCertificateException extends NetCoreException {
  /// Creates a [BadCertificateException] with the given details.
  BadCertificateException({
    required super.requestConfig,
    super.message = 'Bad Certificate',
    super.rawData,
    super.stackTrace,
    super.statusCode,
  });
}
