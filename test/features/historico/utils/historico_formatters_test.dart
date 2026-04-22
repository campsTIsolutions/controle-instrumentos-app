import 'package:controle_instrumentos/features/historico/utils/historico_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns dash for null input', () {
    expect(formatarDataHistorico(null), '-');
  });

  test('returns original input when parsing fails', () {
    expect(formatarDataHistorico('data-invalida'), 'data-invalida');
  });

  test('formats valid ISO string using expected pattern', () {
    final result = formatarDataHistorico('2026-04-20T13:05:00Z');

    expect(result, contains('/'));
    expect(result, contains(' às '));
    expect(result, contains(':'));
  });
}
