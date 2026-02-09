import 'package:flutter_netcore/src/configuration/config_mixin.dart';

/// Configuration class for network adapter settings.
class NetworkConfig with ConfigMixin {
  /// Constructor for NetworkClientConfig.
  NetworkConfig({
    required this.baseUrl,
    this.queryParameters,
    this.baseHeaders,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
  });

  /// Base URL for network requests.
  @override
  final String baseUrl;

  /// Optional headers to be included in network requests.
  final Map<String, dynamic>? baseHeaders;

  /// Optional connection timeout duration.
  @override
  final Duration? connectTimeout;

  /// Optional receive timeout duration.
  @override
  final Duration? receiveTimeout;

  /// Optional send timeout duration.
  @override
  final Duration? sendTimeout;

  /// Query parameters
  @override
  final Map<String, dynamic>? queryParameters;
}
