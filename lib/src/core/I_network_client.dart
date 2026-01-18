import 'package:flutter_netcore/src/index.dart';

/// Abstract class representing a network client for sending requests.
abstract class INetworkClient {
  /// Sends a network request and returns a parsed response.
  Future<TRes?> send<TRes, TReq>({
    required NetworkRequest request,
    TReq? body,
    Parser<TRes>? parser,
    NetworkRetry? retry,
  });
}
