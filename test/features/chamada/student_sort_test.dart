import 'package:controle_instrumentos/features/chamada/models.dart';
import 'package:controle_instrumentos/features/chamada/student_sort.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ordena alunos alfabeticamente ignorando acentos e caixa', () {
    final alunos = [
      StudentRecord(idAluno: 1, name: 'Yuri', attendance: {}),
      StudentRecord(idAluno: 2, name: 'Ysaac', attendance: {}),
      StudentRecord(idAluno: 3, name: 'Yasmin', attendance: {}),
      StudentRecord(idAluno: 4, name: 'Álvaro', attendance: {}),
      StudentRecord(idAluno: 5, name: 'ana', attendance: {}),
      StudentRecord(idAluno: 6, name: 'Érica', attendance: {}),
    ];

    final resultado = ordenarAlunosPorNome(alunos);

    expect(resultado.map((aluno) => aluno.name), [
      'Álvaro',
      'ana',
      'Érica',
      'Yasmin',
      'Ysaac',
      'Yuri',
    ]);
    expect(alunos.first.name, 'Yuri');
  });
}
