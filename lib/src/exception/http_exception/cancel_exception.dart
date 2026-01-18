import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a Cancel HTTP error occurs.
class CancelException extends NetCoreException {
  /// Creates a [CancelException] with the given details.
  CancelException({
      required super.requestConfig,
    super.message = 'Cancel',
    super.rawData,
    super.stackTrace,
        super.statusCode,
  });
}
