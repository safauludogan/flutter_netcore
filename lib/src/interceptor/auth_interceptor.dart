import 'package:dio/dio.dart';
import 'package:flutter_netcore/flutter_netcore.dart';
import 'package:flutter_netcore/src/adapter/adapter_mixin.dart';
import 'package:flutter_netcore/src/configuration/network_request_config.dart';
import 'package:flutter_netcore/src/mapper/dio_error_mapper.dart';

/// Interceptor to handle authentication and token refresh.
class AuthInterceptor extends Interceptor
    with NetworkErrorHandler, AdapterMixin {
  AuthInterceptor({
    required TokenRefreshHandler tokenRefreshHandler,
    required NetworkRequestConfig requestConfig,
  }) : _tokenRefreshHandler = tokenRefreshHandler,
       _requestConfig = requestConfig;

  final TokenRefreshHandler _tokenRefreshHandler;
  final NetworkRequestConfig _requestConfig;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await handleWithRetry(
        action: () async {
          try {
            final requestOptions = err.requestOptions;
            final response = err.response;

            final retryRequestConfig = _requestConfig.copyWith(
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

            // Retry request after token refresh
            final newRequestConfig = newErr.requestConfig;
            if (newRequestConfig == null) {
              return handler.reject(err);
            }
            
            final requestAfterRefreshResponse = await Dio(BaseOptions())
                .request<dynamic>(
                  newErr.requestConfig?.fullUrl ?? '',
                  queryParameters: newErr.requestConfig?.queryParameters,
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
                    method: newErr.requestConfig?.method.name,
                    headers: newErr.requestConfig?.headers,
                    //contentType: newErr.requestConfig?.contentType,
                    sendTimeout: newErr.requestConfig?.sendTimeout,
                    receiveTimeout: newErr.requestConfig?.receiveTimeout,
                  ),
                );
            return handler.resolve(requestAfterRefreshResponse);
          } on DioException catch (e) {
            return handler.reject(e);
          }
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
