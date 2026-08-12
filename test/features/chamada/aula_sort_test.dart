import 'package:controle_instrumentos/features/chamada/aula_sort.dart';
import 'package:controle_instrumentos/features/chamada/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ordena as datas das aulas em ordem cronológica crescente', () {
    final aulas = [
      AulaRecord(id: '18', data: DateTime(2026, 3, 18)),
      AulaRecord(id: '01', data: DateTime(2026, 3, 1)),
      AulaRecord(id: '12', data: DateTime(2026, 3, 12)),
    ];

    final resultado = ordenarAulasPorData(aulas);

    expect(resultado.map((aula) => aula.data.day), [1, 12, 18]);
    expect(aulas.map((aula) => aula.data.day), [18, 1, 12]);
  });
}
