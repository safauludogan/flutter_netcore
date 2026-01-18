import 'package:flutter_netcore/src/exception/netcore_exception.dart';

/// Exception thrown when a No Internet HTTP error occurs.
class NoInternetException extends NetCoreException {
  /// Creates a [NoInternetException] with the given details.
  NoInternetException({
    required super.requestConfig,
    super.message = 'No Internet',
    super.rawData,
    super.stackTrace,
    super.statusCode,
  });
}
