import 'package:flutter_netcore/src/exception/index.dart';
import 'package:flutter_netcore/src/parser/list_parser.dart';
import 'package:test/test.dart';

import 'model/user.dart';

void main() {
  group('ListParser Tests', () {
    test('parses list of maps into list of models', () {
      final parser = ListParser<User>.fromJson(User.fromJson);

      final result = parser.parse([
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ]);

      expect(result.length, 2);
      expect(result.first.id, 1);
      expect(result[0].name, 'Alice');
    });

    test('throws ParsingException if data is not List', () {
      final parser = ListParser<User>.fromJson(User.fromJson);

      expect(
        () => parser.parse({'id': 1}),
        throwsA(isA<ParsingException>()),
      );
    });

    test('throws ParsingException if item parsing fails', () {
      final parser = ListParser<User>.fromJson(
        (_) => throw Exception('invalid item'),
      );

      expect(
        () => parser.parse([
          {'id': 1},
        ]),
        throwsA(isA<ParsingException>()),
      );
    });
  });
}

//group('ModelParser Tests',
