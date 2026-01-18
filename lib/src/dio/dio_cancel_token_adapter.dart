import 'package:dio/dio.dart';
import 'package:flutter_netcore/src/index.dart';

/// Dip cancel token adapter
class DioCancelTokenAdapter implements NetcoreCancelToken {
  DioCancelTokenAdapter({required CancelToken cancelToken})
    : _cancelToken = cancelToken;

  final CancelToken _cancelToken;

  @override
  /// Dio cancel token getter
  dynamic get token => _cancelToken;

  @override
  void cancel([String? reason]) {
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel(reason);
    }
  }

  @override
  bool get isCancelled => _cancelToken.isCancelled;
}
