import 'package:flutter_netcore/src/exception/parsing_exception.dart';
import 'package:flutter_netcore/src/parser/parser.dart';

/// A parser that converts a JSON map into an instance of type [T]
/// using the provided [fromJson] function.
/// The [fromJson] function should take a [Map<String, dynamic>]
/// and return an instance of [T].
class ModelParser<T> extends Parser<T> {
  /// Creates a [ModelParser] with the given [fromJson] function.
  ModelParser(this.fromJson);

  /// A function that converts a JSON map into an instance of [T].
  final T Function(Map<String, dynamic>) fromJson;

  @override
  T parse(dynamic data) {
    if (data == null) {
      throw ParsingException(message: 'Response data is null for type $T');
    }

    if (data is! Map<String, dynamic>) {
      throw ParsingException(
        message:
            'Expected Map<String, dynamic> for $T but got ${data.runtimeType}',
        rawData: data,
      );
    }

    try {
      return fromJson(data);
    } catch (e, stackTrace) {
      throw ParsingException(
        message: 'Failed to parse data into type $T: $e',
        rawData: data,
        stackTrace: stackTrace,
      );
    }
  }
}
