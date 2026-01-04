import 'package:flutter/foundation.dart';
import 'package:flutter_netcore/src/exception/parsing_exception.dart';
import 'package:flutter_netcore/src/parser/model_parser.dart';
import 'package:flutter_netcore/src/parser/parser.dart';

/// A parser that converts a JSON list into a List of type [T]
/// using the provided [dataParser].
/// The [dataParser] should be an instance of [Parser<T>]
/// that can parse individual items of type [T].
@immutable
class ListParser<T> extends Parser<List<T>> {
  /// Creates a [ListParser] with the given [dataParser].
  ListParser(this.dataParser);

  /// Creates a [ListParser] using a [fromJson] function
  /// to parse individual items of type [T].
  /// [ModelParser] and return an instance of [T].
  ///
  /// Example:
  /// ```dart
  /// final parser = ListParser<User>.fromJson(User.fromJson);
  /// final users = parser.parse(jsonList);
  /// ```
  factory ListParser.fromJson(
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return ListParser(ModelParser(fromJson));
  }

  /// Creates a [ListParser] with the given [dataParser].
  final Parser<T> dataParser;

  @override
  List<T> parse(dynamic data) {
    if (data is! List) {
      throw ParsingException(
        message: 'Expected List for List<$T> but got ${data.runtimeType}',
        rawData: data,
      );
    }

    return data.asMap().entries.map((entry) {
      try {
        return dataParser.parse(entry.value);
      } on Exception catch (e, sc) {
        throw ParsingException(
          message: 'Failed to parse item at index ${entry.key} for List<$T>',
          rawData: entry.value,
          stackTrace: sc,
        );
      }
    }).toList();
  }
}
