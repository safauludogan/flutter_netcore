import 'package:dio/dio.dart';
import 'package:flutter_netcore/src/configuration/network_request_config.dart';
import 'package:flutter_netcore/flutter_netcore.dart';
import 'package:flutter_netcore/src/mapper/dio_error_mapper.dart';

/// Interceptor to handle authentication and token refresh.
class AuthInterceptor extends Interceptor with NetworkErrorHandler {
  AuthInterceptor({required TokenRefreshHandler tokenRefreshHandler})
    : _tokenRefreshHandler = tokenRefreshHandler;

  final TokenRefreshHandler _tokenRefreshHandler;
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Handle token refresh logic here
      await handleWithRetry(
        action: () async {
          final requestOptions = err.requestOptions;
          final response = err.response;
          await _tokenRefreshHandler.onRefreshToken(
            DioErrorMapper.map(
              err,
              requestConfig: NetworkRequestConfig(
                baseUrl: requestOptions.baseUrl,
                method: requestOptions.method,
                connectTimeout: requestOptions.connectTimeout,
                receiveTimeout: requestOptions.receiveTimeout,
                sendTimeout: requestOptions.sendTimeout,
                tokenRefreshHandler: _tokenRefreshHandler,
                response: RawNetworkResponse(
                  statusCode: response?.statusCode,
                  headers: response?.headers.map,
                  data: response?.data,
                ),
              ),
            ),
          );
        },
      );
    }

    super.onError(err, handler);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
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
