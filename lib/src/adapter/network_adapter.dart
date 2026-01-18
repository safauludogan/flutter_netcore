import 'package:flutter_netcore/src/index.dart';

/// Abstract class representing a network adapter for making HTTP requests.
abstract class NetworkAdapter {
  /// Sends a network request and returns the response.
  Future<RawNetworkResponse> request<TReq>(
    NetworkRequest request, {
    TReq? body,
  });

  /// Sets global configuration for the adapter
  void setConfig(NetworkConfig config);

  /// Adds interceptors
  void addInterceptor(dynamic interceptor);
}

/*
enum ResponseType {
  /// Transform the response data to JSON object only when the
  /// content-type of response is "application/json" .
  json,

  /// Get the response stream directly,
  /// the [Response.data] will be [ResponseBody].
  ///
  /// ```dart
  /// Response<ResponseBody> rs = await Dio().get<ResponseBody>(
  ///   url,
  ///   options: Options(responseType: ResponseType.stream),
  /// );
  stream,

  /// Transform the response data to an UTF-8 encoded [String].
  plain,

  /// Get the original bytes, the [Response.data] will be [List<int>].
  bytes,
}
*/