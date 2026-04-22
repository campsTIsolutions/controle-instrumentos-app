import 'package:controle_instrumentos/features/alunos/models/aluno_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlunoRecord.fromMap', () {
    test('maps all fields with expected conversions', () {
      final map = {
        'id_aluno': 10,
        'numero_aluno': 123,
        'nome_completo': 'Maria Silva',
        'setor': 'Dança',
        'categoria_usuario': 'Aprendiz',
        'nivel': 'Iniciante',
        'telefone': '11999999999',
        'imagem_url': 'https://img.test/aluno.png',
        'idade': '17',
      };

      final record = AlunoRecord.fromMap(map);

      expect(record.idAluno, 10);
      expect(record.numeroAluno, '123');
      expect(record.nomeCompleto, 'Maria Silva');
      expect(record.setor, 'Dança');
      expect(record.categoriaUsuario, 'Aprendiz');
      expect(record.nivel, 'Iniciante');
      expect(record.telefone, '11999999999');
      expect(record.imagemUrl, 'https://img.test/aluno.png');
      expect(record.idade, 17);
    });

    test('uses safe defaults for null values', () {
      final map = {
        'id_aluno': 1,
        'numero_aluno': null,
        'nome_completo': null,
        'setor': null,
        'categoria_usuario': null,
        'nivel': null,
        'telefone': null,
        'imagem_url': null,
        'idade': null,
      };

      final record = AlunoRecord.fromMap(map);

      expect(record.numeroAluno, '');
      expect(record.nomeCompleto, '');
      expect(record.setor, '');
      expect(record.categoriaUsuario, '');
      expect(record.nivel, '');
      expect(record.telefone, '');
      expect(record.imagemUrl, isNull);
      expect(record.idade, isNull);
    });
  });

  test('toMap serializes fields back to expected keys', () {
    const record = AlunoRecord(
      idAluno: 2,
      numeroAluno: '45',
      nomeCompleto: 'João Santos',
      setor: 'Escudo',
      categoriaUsuario: 'Kids',
      nivel: 'Intermediário',
      telefone: '11888888888',
      imagemUrl: null,
      idade: 14,
    );

    final map = record.toMap();

    expect(map['id_aluno'], 2);
    expect(map['numero_aluno'], '45');
    expect(map['nome_completo'], 'João Santos');
    expect(map['setor'], 'Escudo');
    expect(map['categoria_usuario'], 'Kids');
    expect(map['nivel'], 'Intermediário');
    expect(map['telefone'], '11888888888');
    expect(map['imagem_url'], isNull);
    expect(map['idade'], 14);
  });
}
