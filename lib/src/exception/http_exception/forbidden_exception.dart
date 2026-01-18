import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a 403 Forbidden HTTP error occurs.
class ForbiddenException extends NetCoreException {
  /// Creates a [ForbiddenException] with the given details.
  ForbiddenException({
    required super.requestConfig,
    super.message = 'Forbidden',
    super.rawData,
    super.stackTrace,
  }) : super(
         statusCode: 403,
       );
}
