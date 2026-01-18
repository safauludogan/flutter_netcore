import 'package:flutter_netcore/src/auth/token_refresh_handler.dart';
import 'package:flutter_netcore/src/configuration/config_mixin.dart';

/// Configuration class for network adapter settings.
class NetworkConfig with ConfigMixin {
  /// Constructor for NetworkClientConfig.
  NetworkConfig({
    required this.baseUrl,
    this.tokenRefreshHandler,
    this.headers,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
  });

  /// Base URL for network requests.
  @override
  final String baseUrl;

  /// Optional token refresh handler for authentication.
  final TokenRefreshHandler? tokenRefreshHandler;

  /// Optional headers to be included in network requests.
  final Map<String, dynamic>? headers;

  /// Optional connection timeout duration.
  @override
  final Duration? connectTimeout;

  /// Optional receive timeout duration.
  final Duration? receiveTimeout;

  /// Optional send timeout duration.
  final Duration? sendTimeout;
}
