import 'package:flutter/material.dart';
import 'package:flutter_netcore/flutter_netcore.dart';

class TokenManager extends TokenRefreshHandler {
  late BuildContext context;
  late Future<(String?, String?, dynamic)> Function() onTokenRefreshed;
  late VoidCallback onTokenRefreshFailed;
  TokenManager({
    required this.context,
    required this.onTokenRefreshed,
    required this.onTokenRefreshFailed,
  });
  @override
  Future<NetCoreException> onRefreshToken(NetCoreException exception) async {
    try {
      final snackBarRefreshing = SnackBar(
        content: Text('Refreshing token...'),
        duration: Duration(milliseconds: 500),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBarRefreshing);
      final (newAccessToken, newRefreshToken, response) =
          await onTokenRefreshed();

      exception.requestConfig?.headers?['Authorization'] =
          "Bearer $newAccessToken";

      final snackBarSuccessfully = SnackBar(
        content: Text('Refreshed successfully...'),
        duration: Duration(milliseconds: 500),
        backgroundColor: Colors.green,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBarSuccessfully);
      return exception;
    } catch (e) {
      final snackBarFailed = SnackBar(
        content: Text('Token refresh failed...'),
        duration: Duration(milliseconds: 500),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBarFailed);
      return exception;
    }
  }

  @override
  void onRefreshTokenFail(NetCoreException exception) {
    final snackBar = SnackBar(
      content: Text('Token refresh failed due to error: ${exception.message}'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
