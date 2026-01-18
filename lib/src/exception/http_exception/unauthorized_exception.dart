import 'package:flutter_netcore/src/exception/http_exception/http_exception.dart';

/// Exception thrown when a 401 Unauthorized HTTP error occurs.
class UnauthorizedException extends HttpException {
  /// Creates a [UnauthorizedException] with the given details.
  UnauthorizedException({
    required super.requestConfig,
    super.message = 'Unauthorized',
    super.rawData,
    super.stackTrace,
  }) : super(
         statusCode: 401,
       );
}
