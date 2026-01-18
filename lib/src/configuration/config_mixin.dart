/// Config mixin
mixin ConfigMixin {
  /// BaseUrl
  String get baseUrl;

  /// queryParameters
  late Map<String, dynamic> queryParameters;

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
}
