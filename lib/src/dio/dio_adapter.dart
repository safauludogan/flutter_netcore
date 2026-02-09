import 'package:dio/dio.dart' hide ProgressCallback;
import 'package:flutter_netcore/flutter_netcore.dart';
import 'package:flutter_netcore/src/adapter/adapter_mixin.dart';
import 'package:flutter_netcore/src/configuration/network_request_config.dart';
import 'package:flutter_netcore/src/core/netcore_response_type.dart';
import 'package:flutter_netcore/src/mapper/netcore_error_mapper.dart';

/// Adapter class to integrate Dio with the network client.
/// This class wraps Dio's functionality to send network requests.
/// It translates NetworkRequest objects into Dio requests.
class DioAdapter with AdapterMixin implements NetworkAdapter {
  /// Creates a DioAdapter with an optional Dio instance.
  DioAdapter({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Dio instance used for making HTTP requests.
  final Dio _dio;

  /// Sends a network request using Dio and returns the response.
  /// [request]: The network request to be sent.
  /// [cancelToken]: Optional token to cancel the request.
  @override
  Future<RawNetworkResponse> request<TReq>(
    NetworkRequest request, {
    required NetworkRequestConfig requestConfig,
    TReq? body,
    NetcoreResponseType? responseType,
    NetworkProgress? progress,
  }) async {
    try {
      final dioOptions = requestConfig.toDioOptions();
      final newDioOptions = dioOptions.copyWith(
        responseType: ResponseType.values.firstWhere((r) => r.name == responseType?.name),
      );
      final response = await _dio.request<dynamic>(
        request.path,
        data: body,
        queryParameters: request.queryParameters,
        options: newDioOptions,
        cancelToken: request.cancelToken?.token as CancelToken?,
        onReceiveProgress: (count, total) => emitProgress(progress?.onReceiveProgress, count, total),
        onSendProgress: (count, total) => emitProgress(progress?.onSendProgress, count, total),
      );
      return RawNetworkResponse(
        statusCode: response.statusCode,
        headers: response.headers.map,
        data: response.data,
      );
    } on DioException catch (err) {
      final newRequestConfig = requestConfig.copyWith(
        response: RawNetworkResponse(
          statusCode: err.response?.statusCode,
          headers: err.response?.headers.map,
          data: err.response?.data,
        ),
      );
      throw NetCoreErrorMapper.map(
        err,
        requestConfig: newRequestConfig,
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

  /// Configures the Dio instance with the provided network adapter configuration.
  /// [config]: The network adapter configuration to be applied.
  @override
  void setConfig(NetworkConfig config, ILogger? logger) {
    _dio.options = _dio.options.copyWith(
      baseUrl: config.baseUrl,
      headers: {
        ..._dio.options.headers,
        ...?config.baseHeaders,
      },
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
    );
  }
}
