import 'package:flutter/foundation.dart';
import 'package:flutter_netcore/src/exception/parsing_exception.dart';
import 'package:flutter_netcore/src/parser/parser.dart';

/// If [T] is a primitive type (String, int, double, bool, num),
/// it returns the data as is if it matches the type.
/// For other types, it throws a [ParsingException] indicating
@immutable
class PrimitiveParser<T> extends Parser<T> {
  @override
  T parse(dynamic data) {
    if (data == null) {
      throw ParsingException(message: 'No parser provided for type $T');
    }

    if (_isPrimitive && data is T) {
      return data;
    }

    throw ParsingException(
      message:
          'No parser registered for type $T. '
          'Provide a custom Parser<$T>.',
    );
  }

  bool get _isPrimitive =>
      T == String || T == int || T == double || T == bool || T == num;
}
