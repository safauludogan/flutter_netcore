import 'package:flutter/material.dart';
import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a 404 Not Found HTTP error occurs.
@immutable
class NotFoundException extends NetCoreException {
  /// Creates a [NotFoundException] with the given details.
  NotFoundException({
    super.message = 'Not Found',
    super.rawData,
    super.stackTrace,
  }) : super(
         statusCode: 404,
       );
}
