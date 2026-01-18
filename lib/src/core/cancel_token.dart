/// Can cancel the requests.
abstract class NetcoreCancelToken {
  /// Cancel
  void cancel([String? reason]);

  /// is cancelled request
  bool get isCancelled;

  /// Token
  dynamic get token;
}
