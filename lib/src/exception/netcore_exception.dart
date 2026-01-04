/// An abstract class representing a generic exception in the Netcore library.
/// This class implements the [Exception] interface and provides
/// common properties for all Netcore exceptions.
abstract class NetCoreException implements Exception {
  /// Constructs a [NetCoreException] with the given properties.
  NetCoreException({
    required this.message,
    this.statusCode,
    this.rawData,
    this.stackTrace,
  });

  /// A descriptive message for the exception.
  final String message;

  /// The HTTP status code associated with the exception, if applicable.
  final int? statusCode;

  /// The raw error object that caused the exception.
  final dynamic rawData;
  /// The stack trace at the point where the exception was thrown.
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'NetcoreException: $message (status code: $statusCode)';
  }
}
