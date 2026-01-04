import 'package:flutter/material.dart';
import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a 403 Forbidden HTTP error occurs.
@immutable
class ForbiddenException extends NetCoreException {
  /// Creates a [ForbiddenException] with the given details.
  ForbiddenException({
    super.message = 'Forbidden',
    super.rawData,
    super.stackTrace,
  }) : super(
         statusCode: 403,
       );
}
