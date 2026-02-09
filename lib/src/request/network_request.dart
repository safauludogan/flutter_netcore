import 'package:flutter/cupertino.dart';
import 'package:flutter_netcore/src/core/index.dart';
import 'package:flutter_netcore/src/core/netcore_response_type.dart';

/// Represents a network request with method, path, body, headers, and query parameters.
/// [method] - The HTTP method of the request.
/// [path] - The endpoint path for the request.
/// [queryParameters] - Optional query parameters for the request.
/// [headers] - Optional headers for the request.
/// [cancelToken] - Net core cancel token can cancel requests

@immutable
class NetworkRequest {
  const NetworkRequest(
    this.path, {
    required this.method,
    this.responseType = NetcoreResponseType.json,
    this.headers,
    this.extra,
    this.queryParameters,
    this.cancelToken,
  });

  /// The HTTP method of the request.
  final HttpMethod method;

  /// The endpoint path for the request.
  final String path;

  /// Optional query parameters for the request.
  final Map<String, dynamic>? queryParameters;

  /// Optional headers for the request.
  final Map<String, dynamic>? headers;

  /// Extra
  final Map<String, Object?>? extra;

  /// Net core cancel token
  final NetcoreCancelToken? cancelToken;

  /// Netcore response type
  final NetcoreResponseType responseType;
}
