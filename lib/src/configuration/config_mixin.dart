/// Config mixin
mixin ConfigMixin {
  /// BaseUrl
  String get baseUrl;

  /// queryParameters
  Map<String, dynamic>? get queryParameters;

  /// Connection timeout
  Duration? get connectTimeout => _connectTimeout;
  Duration? _connectTimeout;

  /// connectionTimeout should be positive
  set connectTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('connectTimeout should be positive');
    }
    _connectTimeout = value;
  }

  /// Optional receive timeout duration.
  Duration? get receiveTimeout => _receiveTimeout;
  Duration? _receiveTimeout;

  /// connectionTimeout should be positive
  set receiveTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('receiveTimeout should be positive');
    }
    _receiveTimeout = value;
  }

  /// Optional send timeout duration.
  Duration? get sendTimeout => _sendTimeout;
  Duration? _sendTimeout;

  /// connectionTimeout should be positive
  set sendTimeout(Duration? value) {
    if (value != null && value.isNegative) {
      throw StateError('sendTimeout should be positive');
    }
    _sendTimeout = value;
  }
}
