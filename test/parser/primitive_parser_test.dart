import 'package:flutter_netcore/src/exception/index.dart';
import 'package:flutter_netcore/src/parser/index.dart';
import 'package:test/test.dart';

import 'model/user.dart';

void main() {
  group(
    'AutoParser',
    () {
      test('returns primitive types directly', () {
        final stringParser = PrimitiveParser<String>();
        final intParser = PrimitiveParser<int>();
        final boolParser = PrimitiveParser<bool>();

        expect(stringParser.parse('hello'), 'hello');
        expect(intParser.parse(42), 42);
        expect(boolParser.parse(true), true);
      });

      test('throws ParsingException for null data', () {
        final parser = PrimitiveParser<String>();

        expect(
          () => parser.parse(null),
          throwsA(
            isA<ParsingException>(),
          ),
        );
      });

        test('throws ParsingException for non-primitive types', () {
        final parser = PrimitiveParser<User>();

        expect(
          () => parser.parse({'id': 1}),
          throwsA(
            isA<ParsingException>(),
          ),
        );
      });
    },
  );
}
