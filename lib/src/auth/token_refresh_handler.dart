import 'package:flutter_netcore/src/exception/index.dart';

/// Refresh token handler
abstract class TokenRefreshHandler {
  /// When refresh
  Future<NetCoreException> onRefreshToken(NetCoreException exception);
  /// When refresh token fail
  void onRefreshTokenFail(NetCoreException exception);
}
