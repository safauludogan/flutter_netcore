import 'package:flutter/material.dart';
import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a 500 Server Error HTTP error occurs.
@immutable
class ServerException extends NetCoreException {
  /// Creates a [ServerException] with the given details.
    ServerException({
    super.message = 'Server Error',
    super.statusCode,
    super.rawData,
    super.stackTrace,
  });
}
