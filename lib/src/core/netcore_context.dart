/// Progress callback
typedef ProgressCallback =
    void Function(
      int transferred,
      int total,
      double progress, // 0.0 - 1.0
    );

/// Progress callback context
class NetcoreContext {
  NetcoreContext({
    required this.onSendProgress,
    required this.onReceiveProgress,
  });

  /// onSendProgress callback
  final ProgressCallback? onSendProgress;

  /// onReceiveProgress callback
  final ProgressCallback? onReceiveProgress;
}
