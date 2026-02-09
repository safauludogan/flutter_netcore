import 'package:flutter_netcore/flutter_netcore.dart';

/// Refresh token handler
/// Should return a NetCoreException that contains updated requestConfig
typedef RefreshTokenHandler =
    Future<NetCoreException?> Function(
      NetCoreException exception,
    );

/// Called when refresh token completely fails
typedef RefreshTokenFailHandler =
    Future<void> Function(
      NetCoreException exception,
    );
