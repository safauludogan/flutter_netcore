import 'package:dio/dio.dart';
import 'package:flutter_netcore/src/configuration/network_request_config.dart';
import 'package:flutter_netcore/src/exception/http_exception/no_internet_exception.dart';
import 'package:flutter_netcore/src/exception/index.dart';

/// Maps DioException to NetCoreException.
class DioErrorMapper {
  /// Maps a Dio [exception] to a corresponding [NetCoreException].
  static NetCoreException map(
    Exception exception, {
    required NetworkRequestConfig requestConfig,
  }) {
    if (exception is! DioException) {
      return NetCoreException(
        message: exception.toString(),
        requestConfig: requestConfig,
      );
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        return ConnectionTimeoutException(requestConfig: requestConfig);
      case DioExceptionType.sendTimeout:
        return SendTimeoutException(requestConfig: requestConfig);
      case DioExceptionType.receiveTimeout:
        return ReceiveTimeoutException(requestConfig: requestConfig);
      case DioExceptionType.badCertificate:
        return BadCertificateException(requestConfig: requestConfig);
      case DioExceptionType.badResponse:
        return _mapBadResponse(exception, requestConfig: requestConfig);
      case DioExceptionType.cancel:
        return CancelException(requestConfig: requestConfig);
      case DioExceptionType.connectionError:
        return ConnectionErrorException(requestConfig: requestConfig);
      case DioExceptionType.unknown:
        final error = exception.error;

        if (error is SocketException) {
          return NoInternetException(requestConfig: requestConfig);
        }

        if (error is FormatException) {
          return ParsingException(
            message: error.message,
            requestConfig: requestConfig,
          );
        }

        return UnknownException(
          message: error?.toString(),
          requestConfig: requestConfig,
        );
    }
  }

  static NetCoreException _mapBadResponse(
    DioException exception, {
    required NetworkRequestConfig requestConfig,
  }) {
    final statusCode = exception.response?.statusCode;
    final data = exception.response?.data;

    final serverMessage = _extractMessage(data);

    if (statusCode != null) {
      if (statusCode >= 500 && statusCode <= 599) {
        return ServerException(
          statusCode: statusCode,
          message: serverMessage,
          requestConfig: requestConfig,
        );
      }

      switch (statusCode) {
        case 400:
          return BadRequestException(
            message: serverMessage,
            requestConfig: requestConfig,
          );

        case 401:
          return UnauthorizedException(
            message: serverMessage,
            requestConfig: requestConfig,
          );

        case 403:
          return ForbiddenException(
            message: serverMessage,
            requestConfig: requestConfig,
          );

        case 404:
          return NotFoundException(
            message: serverMessage,
            requestConfig: requestConfig,
          );

        case 409:
          return ConflictException(
            message: serverMessage,
            requestConfig: requestConfig,
          );
      }
    }

    return BadResponseException(
      statusCode: statusCode,
      message: serverMessage,
      requestConfig: requestConfig,
    );
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) return data;

    if (data is Map<String, dynamic>) {
      final candidates = ['message', 'error', 'detail', 'title'];

      for (final key in candidates) {
        final value = data[key];
        if (value != null) return value.toString();
      }
    }

    return null;
  }
}
