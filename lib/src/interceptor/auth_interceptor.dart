import 'package:dio/dio.dart';
import 'package:flutter_netcore/flutter_netcore.dart';
import 'package:flutter_netcore/src/adapter/adapter_mixin.dart';
import 'package:flutter_netcore/src/configuration/network_request_config.dart';
import 'package:flutter_netcore/src/mapper/dio_error_mapper.dart';

/// Interceptor to handle authentication and token refresh.
class AuthInterceptor extends Interceptor
    with NetworkRetryHandlerMixin, AdapterMixin {
  AuthInterceptor({
    required TokenRefreshHandler tokenRefreshHandler,
    required ILogger? logger,
  }) : _tokenRefreshHandler = tokenRefreshHandler,
       _logger = logger;

  final TokenRefreshHandler _tokenRefreshHandler;
  final ILogger? _logger;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;

    if (err.response?.statusCode == 401) {
      _logger?.log(
        '🔐 401 detected '
        '[${requestOptions.method} ${requestOptions.path}]',
        level: LogLevel.warning,
      );

      try {
        await handleWithRetry(
          action: () async {
            try {
              _logger?.log(
                '🔐 Auth refresh started '
                '[${requestOptions.method} ${requestOptions.path}]',
              );

              final response = err.response;

              final retryRequestConfig =
                  NetworkRequestConfig(
                    baseUrl: requestOptions.baseUrl,
                    path: requestOptions.path,
                    method: HttpMethod.getByName(requestOptions.method),
                    queryParameters: requestOptions.queryParameters,
                    headers: requestOptions.headers as Map<String, dynamic>?,
                  ).copyWith(
                    response: RawNetworkResponse(
                      statusCode: response?.statusCode,
                      headers: response?.headers.map,
                      data: response?.data,
                    ),
                  );

              final netCoreError = DioErrorMapper.map(
                err,
                requestConfig: retryRequestConfig,
              );

              final newErr = await _tokenRefreshHandler.onRefreshToken(
                netCoreError,
              );

              final newRequestConfig = newErr.requestConfig;
              if (newRequestConfig == null) {
                _logger?.log(
                  '❌ Auth refresh succeeded but requestConfig is null '
                  '[${requestOptions.method} ${requestOptions.path}]',
                  level: LogLevel.error,
                );
                return handler.reject(err);
              }

              _logger?.log(
                '✅ Auth refresh succeeded '
                '[${requestOptions.method} ${requestOptions.path}]',
              );

              final requestAfterRefreshResponse = await Dio(BaseOptions())
                  .request<dynamic>(
                    newRequestConfig.fullUrl,
                    queryParameters: newRequestConfig.queryParameters,
                    data: requestOptions.data,
                    onReceiveProgress: (count, total) => emitProgress(
                      retryRequestConfig.progress?.onReceiveProgress,
                      count,
                      total,
                    ),
                    onSendProgress: (count, total) => emitProgress(
                      retryRequestConfig.progress?.onSendProgress,
                      count,
                      total,
                    ),
                    cancelToken: requestOptions.cancelToken,
                    options: Options(
                      method: newRequestConfig.method.name,
                      headers: newRequestConfig.headers,
                      sendTimeout: newRequestConfig.sendTimeout,
                      receiveTimeout: newRequestConfig.receiveTimeout,
                    ),
                  );

              _logger?.log(
                '🔁 Retrying request after auth refresh '
                '[${newRequestConfig.method.name} ${newRequestConfig.fullUrl}]',
                level: LogLevel.debug,
              );
              return handler.resolve(requestAfterRefreshResponse);
            } on DioException catch (e) {
              _logger?.log(
                '❌ Retry request failed after auth refresh '
                '[${requestOptions.method} ${requestOptions.path}] '
                'error=$e',
                level: LogLevel.error,
              );
              return handler.reject(e);
            }
          },
        );

        return;
      } on NetCoreException catch (e) {
        _logger?.log(
          '❌ Auth refresh failed '
          '[${requestOptions.method} ${requestOptions.path}] '
          'error=$e',
          level: LogLevel.error,
        );

        return handler.next(err);
      }
    }

    super.onError(err, handler);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    return handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    return handler.next(response);
  }
}
