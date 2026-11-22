import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/core/database/record_id.dart';

void main() {
  group('local row IDs and record IDs', () {
    test('convert both ways without loss', () {
      for (final rowId in [1, 42, 9007199254740991]) {
        expect(rowIdOf(recordIdOf(rowId)), rowId);
      }
      expect(recordIdOf(42), '42');
    });

    test('null passes through the nullable forms', () {
      expect(recordIdOrNull(null), isNull);
      expect(rowIdOrNull(null), isNull);
      expect(recordIdOrNull(7), '7');
      expect(rowIdOrNull('7'), 7);
    });

    test('a record ID that is not a local key is rejected', () {
      for (final recordId in [
        '3f2b8c1e-9a4d-4e7b-8c21-5d6f7a8b9c0d',
        '',
        '007',
        '+7',
        ' 7',
        '7.0',
      ]) {
        expect(() => rowIdOf(recordId), throwsArgumentError, reason: recordId);
      }
    });
  });
}
