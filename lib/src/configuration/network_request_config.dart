import 'package:dio/dio.dart';
import 'package:flutter_netcore/flutter_netcore.dart';
import 'package:flutter_netcore/src/configuration/config_mixin.dart';

/// Network request config
class NetworkRequestConfig with ConfigMixin {
  NetworkRequestConfig({
    required this.baseUrl,
    required this.path,
    required this.method,
    this.queryParameters,
    this.response,
    this.progress,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.extra,
    Map<String, dynamic>? headers,
  }) : headers = headers?.map((k, v) => MapEntry(k, v?.toString() ?? ''));

  /// Response
  final RawNetworkResponse? response;

  /// HttpMethod
  final HttpMethod method;

  /// Base URL for network requests.
  @override
  final String baseUrl;

  /// Path for the network request.
  final String path;

  /// Query parameters
  @override
  final Map<String, dynamic>? queryParameters;

  /// Full URL
  /// Combines baseUrl and path to form the full URL.
  String get fullUrl {
    try {
      final uri = Uri.parse(baseUrl);
      return uri.resolve(path).toString();
    } on Exception catch (_) {
      return '$baseUrl$path';
    }
  }

  /// Optional progress callback for tracking request progress.
  final NetworkProgress? progress;

  /// Optional connection timeout duration.
  @override
  final Duration? connectTimeout;

  @override
  /// Optional receive timeout duration.
  final Duration? receiveTimeout;

  @override
  /// Optional send timeout duration.
  final Duration? sendTimeout;

  /// Headers
  final Map<String, String>? headers;

  /// Extra
  final Map<String, Object?>? extra;

  /// Skip auth handling
  bool get skipAuthHandling => extra?['skipAuthHandling'] == true;

  /// Copy with factory class
  NetworkRequestConfig copyWith({
    String? baseUrl,
    String? path,
    HttpMethod? method,
    Map<String, dynamic>? queryParameters,
    RawNetworkResponse? response,
    NetworkProgress? progress,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, String>? headers,
    Map<String, Object?>? extra,
  }) {
    return NetworkRequestConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      path: path ?? this.path,
      method: method ?? this.method,
      queryParameters: queryParameters ?? this.queryParameters,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      progress: progress ?? this.progress,
      response: response ?? this.response,
      headers: headers ?? this.headers,
      extra: extra ?? this.extra,
    );
  }

  /// Convert to Dio Options
  Options toDioOptions({ResponseType responseType = ResponseType.json}) {
    return Options(
      method: method.name,
      headers: headers,
      extra: extra,
      responseType: responseType,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
    );
  }

  // Factory from existing NetworkRequest + global NetworkConfig
  factory NetworkRequestConfig.fromNetworkRequest(
    NetworkConfig baseConfig,
    NetworkRequest request, {
    NetworkProgress? progress,
  }) {
    return NetworkRequestConfig(
      baseUrl: baseConfig.baseUrl,
      path: request.path,
      method: request.method,
      extra: request.extra,
      queryParameters: request.queryParameters,
      headers: request.headers?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      connectTimeout: baseConfig.connectTimeout,
      receiveTimeout: baseConfig.receiveTimeout,
      sendTimeout: baseConfig.sendTimeout,
      progress: progress,
    );
  }

  @override
  String toString() {
    return '''
        NetworkRequestConfig(
          baseUrl: $baseUrl,
          path: $path,
          method: $method,
          queryParameters: $queryParameters,
          connectTimeout: $connectTimeout,
          receiveTimeout: $receiveTimeout,
          sendTimeout: $sendTimeout,
          progress: $progress,
          response: $response,
          headers: $headers,
          extra: $extra,
        )
        ''';
  }
}
