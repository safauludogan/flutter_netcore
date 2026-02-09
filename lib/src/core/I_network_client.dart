import 'package:flutter_netcore/flutter_netcore.dart';

/// Abstract class representing a network client for sending requests.
abstract class INetworkClient {
  /// Sends a network request and returns a parsed response.
  Future<TRes?> send<TRes, TReq>({
    required NetworkRequest request,
    TReq? body,
    Parser<TRes>? parser,
    NetworkProgress? progress,
  });

  /// Optional handler for refreshing tokens when authentication fails.
  RefreshTokenHandler? refreshTokenHandler;

  /// Optional handler for handling token refresh failures.
  RefreshTokenFailHandler? refreshTokenFailHandler;
}
