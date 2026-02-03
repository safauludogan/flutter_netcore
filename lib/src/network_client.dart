import 'package:flutter_netcore/flutter_netcore.dart';
import 'package:flutter_netcore/src/configuration/network_request_config.dart';
import 'package:flutter_netcore/src/exception/adapter_exception.dart';

class NetworkClient with NetworkErrorHandler implements INetworkClient {
  NetworkClient({
    required NetworkConfig config,
    ILogger? logger,
    NetworkRetry? retry,
    NetworkAdapter? adapter,
  }) : _adapter = adapter ?? DioAdapter(),
       _config = config,
       _logger = logger,
       _retry = retry {
    _setup();
  }

  /// Network adapter used to send requests.
  final NetworkAdapter? _adapter;

  /// Configuration for the network client.
  final NetworkConfig _config;

  /// Console logger
  final ILogger? _logger;

  final NetworkRetry? _retry;

  void _setup() {
    if (_adapter == null) {
      throw AdapterException(
        message: 'Adapter should be exists',
      );
    }
    _adapter.setConfig(_config);
  }

  @override
  Future<TRes?> send<TRes, TReq>({
    required NetworkRequest request,
    TReq? body,
    Parser<TRes>? parser,
    NetworkProgress? progress,
  }) async {
    return handleWithRetry<TRes>(
      networkRetry: _retry,
      logger: _logger,
      action: () async {
        /// request config
        final requestConfig = NetworkRequestConfig.fromNetworkRequest(
          _config,
          request,
        );
        _logger?.logRequest<TReq>(request: request, config: _config);

        final response = await _adapter!.request<TReq>(
          request,
          body: body,
          progress: progress,
          requestConfig: requestConfig
        );

        _logger?.logResponse(
          request: request,
          config: _config,
          response: response,
        );

        final data = response.data;

        if (parser != null) return parser.parse(data);
        if (TRes.toString() == 'dynamic') return data as TRes;
        if (TRes.toString() == 'Map<String, dynamic>') return data as TRes;
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
