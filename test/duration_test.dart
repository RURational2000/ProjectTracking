import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UTC duration calculation', () {
    test('returns 9 for 9m 59s', () {
      final start = DateTime(2026, 1, 6, 10, 0, 0);
      final end = start.add(const Duration(minutes: 9, seconds: 59));
      final minutes = end.toUtc().difference(start.toUtc()).inMinutes;
      expect(minutes, 9);
    });

    test('returns 10 for exactly 10 minutes', () {
      final start = DateTime(2026, 1, 6, 10, 0, 0);
      final end = start.add(const Duration(minutes: 10));
      final minutes = end.toUtc().difference(start.toUtc()).inMinutes;
      expect(minutes, 10);
    });

    test('works across hour boundary', () {
      final start = DateTime(2026, 1, 6, 10, 55, 0);
      final end = start.add(const Duration(minutes: 15)); // 11:10
      final minutes = end.toUtc().difference(start.toUtc()).inMinutes;
      expect(minutes, 15);
    });
  });
}
