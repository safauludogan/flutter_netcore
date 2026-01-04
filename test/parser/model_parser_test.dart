import 'package:flutter_netcore/src/exception/index.dart';
import 'package:flutter_netcore/src/parser/index.dart';
import 'package:test/test.dart';

import 'model/user.dart';

void main() {
  group('ModelParser Tests', () {
    test('parses valid Map into model', () {
      final parser = ModelParser<User>(
        User.fromJson,
      );
      final result = parser.parse({'id': 1, 'name': 'John Doe', 'email': ''});

      expect(result.id, 1);
      expect(result.name, 'John Doe');
    });

    test('throws ParsingException if data is not Map', () {
      final parser = ModelParser<User>(
        User.fromJson,
      );

      expect(
        () => parser.parse(['invalid']),
        throwsA(isA<ParsingException>()),
      );
    });

    test('wraps fromJson errors into ParsingException', () {
      final parser = ModelParser<User>(
        (_) => throw Exception('boom'),
      );

      expect(
        () => parser.parse({'id': 1}),
        throwsA(isA<ParsingException>()),
      );
    });
  });
}
