import 'package:flutter_netcore/src/exception/index.dart';

/// Refresh token handler
abstract class TokenRefreshHandler {
  /// When refresh
  Future<bool> onRefreshToken(NetCoreException exception);
  /// When refresh token fail
  void onRefreshTokenFail(NetCoreException exception);
}
