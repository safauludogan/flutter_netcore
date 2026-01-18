import 'package:flutter_netcore/src/configuration/config_mixin.dart';
import 'package:flutter_netcore/src/index.dart';

/// Network request config
class NetworkRequestConfig with ConfigMixin {
  NetworkRequestConfig({
    required this.baseUrl,
    required this.method,
    this.response,
    this.tokenRefreshHandler,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
  });

  /// Response
  final RawNetworkResponse? response;

  /// HttpMethod
  final String method;

  /// Base URL for network requests.
  @override
  final String baseUrl;

  /// Optional token refresh handler for authentication.
  final TokenRefreshHandler? tokenRefreshHandler;

  /// Optional connection timeout duration.
  @override
  final Duration? connectTimeout;

  /// Optional receive timeout duration.
  final Duration? receiveTimeout;

  /// Optional send timeout duration.
  final Duration? sendTimeout;

  /// Copy with factory class
  NetworkRequestConfig copyWith({
    String? baseUrl,
    String? method,
    RawNetworkResponse? response,
    TokenRefreshHandler? tokenRefreshHandler,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    return NetworkRequestConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      method: method ?? this.method,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      tokenRefreshHandler: tokenRefreshHandler ?? this.tokenRefreshHandler,
      response: response ?? this.response,
    );
  }
}
