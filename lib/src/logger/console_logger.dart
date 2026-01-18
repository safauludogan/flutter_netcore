import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_netcore/flutter_netcore.dart';
import 'package:flutter_netcore/src/logger/I_logger.dart';

/// Console logger
class ConsoleLogger extends ILogger {
  ConsoleLogger({
    required this.enabled,
    required this.minimumLevel,
  });

  /// enable logger with this parameter
  final bool enabled;

  /// Log level
  final LogLevel minimumLevel;

  @override
  void log(String message, {LogLevel level = LogLevel.info}) {
    if (!enabled || level.index < minimumLevel.index) return;

    final prefix = _getPrefix(level);
    developer.log('$prefix $message', name: 'HttpClient');
  }

  @override
  void logRequest<TReq>({
    required NetworkRequest request,
    required NetworkConfig config,
    TReq? body,
  }) {
    if (!enabled) return;

    final uri = Uri.parse(config.baseUrl).resolve(request.path).toString();

    final buffer = StringBuffer()
      ..writeln('╔═══════════════════════════════════════════════════')
      ..writeln('║ REQUEST')
      ..writeln('╟───────────────────────────────────────────────────')
      ..writeln('║ Method: ${request.method}')
      ..writeln('║ Uri: $uri');

    final headers = <String, dynamic>{};
    if (config.headers != null) {
      headers.addAll(config.headers!);
    }
    if (request.headers != null) {
      headers.addAll(request.headers!);
    }
    buffer.writeln('║ Headers:');
    headers.forEach((key, value) {
      buffer.writeln('║   $key: $value');
    });

    if (body != null) {
      buffer
        ..writeln('║ Body:')
        ..writeln('║   ${_formatData(body)}');
    }

    buffer.writeln('╚═══════════════════════════════════════════════════');

    developer.log(buffer.toString(), name: 'HttpClient');
  }

  @override
  void logResponse({
    required NetworkRequest request,
    required NetworkConfig config,
    required RawNetworkResponse response,
  }) {
    if (!enabled) return;

    final uri = Uri.parse(config.baseUrl).resolve(request.path).toString();

    final buffer = StringBuffer()
      ..writeln('╔═══════════════════════════════════════════════════')
      ..writeln('║ RESPONSE')
      ..writeln('╟───────────────────────────────────────────────────')
      ..writeln('║ Method: ${request.method}')
      ..writeln('║ Uri: $uri')
      ..writeln(
        '║ Status: ${response.statusCode}',
      );

    if (response.data != null) {
      buffer
        ..writeln('║ Body:')
        ..writeln('║   ${_formatData(response.data)}');
    }

    buffer.writeln('╚═══════════════════════════════════════════════════');

    developer.log(buffer.toString(), name: 'HttpClient');
  }

  @override
  void logError(NetCoreException error) {
    if (!enabled) return;

    final buffer = StringBuffer()
      ..writeln('╔═══════════════════════════════════════════════════')
      ..writeln('║ ERROR')
      ..writeln('╟───────────────────────────────────────────────────')
      ..writeln('║ Method: ${error.requestConfig?.method}')
      ..writeln('║ Uri: ${error.requestConfig?.baseUrl}')
      ..writeln('║ Type: $error')
      ..writeln('║ Message: ${error.message}')
      ..writeln('║ Raw data: ${error.rawData}');

    if (error.requestConfig?.response != null) {
      buffer
        ..writeln('║ Status: ${error.requestConfig?.response?.statusCode}')
        ..writeln(
          '║ Response: ${_formatData(error.requestConfig?.response?.data)}',
        );
    }

    buffer.writeln('╚═══════════════════════════════════════════════════');

    developer.log(buffer.toString(), name: 'HttpClient', level: 1000);
  }

  String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛 DEBUG';
      case LogLevel.info:
        return 'ℹ️ INFO';
      case LogLevel.warning:
        return '⚠️ WARNING';
      case LogLevel.error:
        return '❌ ERROR';
    }
  }

  String _formatData(dynamic data) {
    if (data == null) return 'null';

    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      return data.toString();
    } on Exception catch (_) {
      return data.toString();
    }
  }
}
