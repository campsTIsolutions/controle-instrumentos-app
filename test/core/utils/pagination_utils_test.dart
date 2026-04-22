import 'package:controle_instrumentos/core/utils/pagination_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pagedSlice', () {
    test('returns first page correctly', () {
      final items = List.generate(25, (i) => i + 1);

      final result = pagedSlice(
        items: items,
        currentPage: 1,
        itemsPerPage: 10,
      );

      expect(result, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    });

    test('returns middle page correctly', () {
      final items = List.generate(25, (i) => i + 1);

      final result = pagedSlice(
        items: items,
        currentPage: 2,
        itemsPerPage: 10,
      );

      expect(result, [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
    });

    test('returns partial last page correctly', () {
      final items = List.generate(25, (i) => i + 1);

      final result = pagedSlice(
        items: items,
        currentPage: 3,
        itemsPerPage: 10,
      );

      expect(result, [21, 22, 23, 24, 25]);
    });

    test('returns empty list when page exceeds bounds', () {
      final items = List.generate(10, (i) => i + 1);

      final result = pagedSlice(
        items: items,
        currentPage: 5,
        itemsPerPage: 10,
      );

      expect(result, isEmpty);
    });
  });

  group('pageCount', () {
    test('returns 1 for empty total', () {
      expect(pageCount(totalItems: 0, itemsPerPage: 10), 1);
    });

    test('returns exact page count when divisible', () {
      expect(pageCount(totalItems: 20, itemsPerPage: 10), 2);
    });

    test('rounds up for partial page', () {
      expect(pageCount(totalItems: 21, itemsPerPage: 10), 3);
    });
  });
}
