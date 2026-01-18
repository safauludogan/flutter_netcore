import 'package:flutter_netcore/src/configuration/network_request_config.dart';
import 'package:flutter_netcore/src/exception/adapter_exception.dart';
import 'package:flutter_netcore/src/index.dart';

class NetworkClient with NetworkErrorHandler implements INetworkClient {
  NetworkClient({
    required NetworkConfig config,
    ILogger? logger,
    NetworkAdapter? adapter,
  }) : _adapter = adapter ?? DioAdapter(),
       _config = config,
       _logger = logger {
    _setup();
  }

  /// Network adapter used to send requests.
  final NetworkAdapter? _adapter;

  /// Configuration for the network client.
  final NetworkConfig _config;

  /// Console logger
  final ILogger? _logger;

  void _setup() {
    if (_adapter == null) {
      throw AdapterException(
        message: 'Adapter should be exists',
      );
    }
    _adapter.setConfig(_config);

    if (_config.tokenRefreshHandler != null) {
      _adapter.addInterceptor(
        AuthInterceptor(tokenRefreshHandler: _config.tokenRefreshHandler!),
      );
    }
  }

  @override
  Future<TRes?> send<TRes, TReq>({
    required NetworkRequest request,
    TReq? body,
    Parser<TRes>? parser,
    NetworkRetry? retry,
  }) async {
    return handleWithRetry<TRes>(
      networkRetry: retry,
      logger: _logger,
      action: () async {
        /// request config
        final requestConfig = NetworkRequestConfig(
          baseUrl: _config.baseUrl,
          method: request.method.name,
          connectTimeout: _config.connectTimeout,
          receiveTimeout: _config.receiveTimeout,
          sendTimeout: _config.sendTimeout,
          tokenRefreshHandler: _config.tokenRefreshHandler,
        );

        final response = await _adapter!.request<TReq>(
          request,
          body: body,
        );

        final data = response.data;

        if (parser != null) return parser.parse(data);

        if (TRes == dynamic) return data as TRes;
        if (TRes is Map<String, dynamic>) return data as TRes;
        if (TRes.toString() == 'void' || TRes == Never) return Future.value();

        final copyRequestConfig = requestConfig.copyWith(response: response);
        final exception = ParsingException(
          message: 'No parser provided for $TRes',
          statusCode: response.statusCode,
          rawData: data,
          requestConfig: copyRequestConfig,
        );
        _logger?.logError(exception);
        throw exception;
      },
    );
  }
}
