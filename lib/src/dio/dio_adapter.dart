import 'package:dio/dio.dart';
import 'package:flutter_netcore/src/configuration/network_request_config.dart';
import 'package:flutter_netcore/src/index.dart';
import 'package:flutter_netcore/src/mapper/dio_error_mapper.dart';

/// Adapter class to integrate Dio with the network client.
/// This class wraps Dio's functionality to send network requests.
/// It translates NetworkRequest objects into Dio requests.
class DioAdapter implements NetworkAdapter {
  /// Creates a DioAdapter with an optional Dio instance.
  DioAdapter({Dio? dio}) : _dio = dio ?? Dio();

  /// Dio instance used for making HTTP requests.
  final Dio _dio;

  /// Sends a network request using Dio and returns the response.
  /// [request]: The network request to be sent.
  /// [cancelToken]: Optional token to cancel the request.
  @override
  Future<RawNetworkResponse> request<TReq>(
    NetworkRequest request, {
    TReq? body,
    ResponseType? responseType,
  }) async {
    try {
      final options = Options(
        headers: request.headers,
        method: request.method.name,
        responseType: responseType ?? ResponseType.json,
      );
      final response = await _dio.request<dynamic>(
        request.path,
        data: body,
        queryParameters: request.queryParameters,
        options: options,
        cancelToken: request.cancelToken?.token as CancelToken?,
      );
      return RawNetworkResponse(
        statusCode: response.statusCode,
        headers: response.headers.map,
        data: response.data,
      );
    } on DioException catch (err) {
      final requestOptions = err.requestOptions;

      throw DioErrorMapper.map(
        err,
        requestConfig: NetworkRequestConfig(
          baseUrl: requestOptions.baseUrl,
          method: requestOptions.method,
          connectTimeout: requestOptions.connectTimeout,
          receiveTimeout: requestOptions.receiveTimeout,
          sendTimeout: requestOptions.sendTimeout,
          response: RawNetworkResponse(
            statusCode: err.response?.statusCode,
            headers: err.response?.headers.map,
            data: err.response?.data,
          ),
        ),
      );
    }
  }

  /// Adds an interceptor to the Dio instance.
  /// [interceptor]: The interceptor to be added.
  @override
  void addInterceptor(dynamic interceptor) {
    if (interceptor is Interceptor) {
      _dio.interceptors.add(interceptor);
    }
  }

  /* /// Add on logger interceptor to the Dio
  /// [ILogger]: The console logger for dio logger interceptor
  @override
  void addLogger(ILogger logger) {
    _dio.interceptors.add(
      LogInterceptor(
        logPrint: (obj) => logger.log(obj.toString()),
      ),
    );
  }*/

  /// Configures the Dio instance with the provided network adapter configuration.
  /// [config]: The network adapter configuration to be applied.
  @override
  void setConfig(NetworkConfig config) {
    _dio.options = _dio.options.copyWith(
      baseUrl: config.baseUrl,
      headers: {
        ..._dio.options.headers,
        ...?config.headers,
      },
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
    );
  }
}
