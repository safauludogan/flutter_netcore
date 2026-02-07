import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_netcore/flutter_netcore.dart';

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
    final color = _getColorForLevel(level);
    developer.log(_colorize('$prefix $message', color), name: 'HttpClient');
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
      ..writeln(
        _colorize(
          '╔═══════════════════════════════════════════════════',
          _blue,
        ),
      )
      ..writeln(_colorize('║ REQUEST', _blue))
      ..writeln(
        _colorize(
          '╟───────────────────────────────────────────────────',
          _blue,
        ),
      )
      ..writeln(_colorize('║ Method: ${request.method}', _blue))
      ..writeln(_colorize('║ Uri: $uri', _blue));

    final headers = <String, dynamic>{};
    if (config.baseHeaders != null) {
      headers.addAll(config.baseHeaders!);
    }
    if (request.headers != null) {
      headers.addAll(request.headers!);
    }
    buffer.writeln(_colorize('║ Headers:', _blue));
    headers.forEach((key, value) {
      buffer.writeln(_colorize('║   $key: $value', _blue));
    });

    if (body != null) {
      buffer
        ..writeln(_colorize('║ Body:', _blue))
        ..writeln(_formatDataColored(body, _blue));
    }

    buffer.writeln(
      _colorize('╚═══════════════════════════════════════════════════', _blue),
    );

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
      ..writeln(
        _colorize(
          '╔═══════════════════════════════════════════════════',
          _green,
        ),
      )
      ..writeln(_colorize('║ RESPONSE', _green))
      ..writeln(
        _colorize(
          '╟───────────────────────────────────────────────────',
          _green,
        ),
      )
      ..writeln(_colorize('║ Method: ${request.method}', _green))
      ..writeln(_colorize('║ Uri: $uri', _green))
      ..writeln(
        _colorize('║ Status: ${response.statusCode}', _green),
      );

    if (response.data != null) {
      buffer
        ..writeln(_colorize('║ Body:', _green))
        ..writeln(_formatDataColored(response.data, _green));
    }

    buffer.writeln(
      _colorize('╚═══════════════════════════════════════════════════', _green),
    );

    developer.log(buffer.toString(), name: 'HttpClient');
  }

  @override
  void logError(NetCoreException error) {
    if (!enabled) return;

    final buffer = StringBuffer()
      ..writeln(
        _colorize('╔═══════════════════════════════════════════════════', _red),
      )
      ..writeln(_colorize('║ ERROR', _red))
      ..writeln(
        _colorize('╟───────────────────────────────────────────────────', _red),
      )
      ..writeln(_colorize('║ Method: ${error.requestConfig?.method}', _red))
      ..writeln(_colorize('║ Uri: ${error.requestConfig?.baseUrl}', _red))
      ..writeln(_colorize('║ Type: $error', _red))
      ..writeln(_colorize('║ Message: ${error.message}', _red))
      ..writeln(_colorize('║ Raw data: ${error.rawData}', _red));

    if (error.requestConfig?.response != null) {
      buffer
        ..writeln(
          _colorize(
            '║ Status: ${error.requestConfig?.response?.statusCode}',
            _red,
          ),
        )
        ..writeln(
          _formatDataColored(error.requestConfig?.response?.data, _red),
        );
    }

    buffer.writeln(
      _colorize('╚═══════════════════════════════════════════════════', _red),
    );

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

  String _formatDataColored(dynamic data, String color) {
    final formatted = _formatData(data);
    return formatted
        .split('\n')
        .map((line) => _colorize('║   $line', color))
        .join('\n');
  }

  // ANSI color codes
  static const String _reset = '\u001b[0m';
  static const String _gray = '\u001b[90m';
  static const String _blue = '\u001b[34m';
  static const String _green = '\u001b[32m';
  static const String _yellow = '\u001b[33m';
  static const String _red = '\u001b[31m';

  String _colorize(String text, String color) => '$color$text$_reset';

  String _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return _gray;
      case LogLevel.info:
        return _blue;
      case LogLevel.warning:
        return _yellow;
      case LogLevel.error:
        return _red;
    }
  }
}
