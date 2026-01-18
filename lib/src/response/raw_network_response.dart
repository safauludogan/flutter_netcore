/// Represents a raw network response with data, status code, and headers.
class RawNetworkResponse {
  /// Constructs a [RawNetworkResponse] instance.
  const RawNetworkResponse({
    required this.data,
    required this.statusCode,
    this.headers,
  });

  /// The response data.
  final dynamic data;

  /// The HTTP status code.
  final int? statusCode;

  /// The response headers.
  final Map<String, List<String>>? headers;
}
