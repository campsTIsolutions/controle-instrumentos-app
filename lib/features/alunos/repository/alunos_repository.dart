import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aluno_record.dart';

class AlunosRepository {
  AlunosRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<AlunoRecord>> listarAlunos() async {
    final response = await _supabase
        .from('alunos')
        .select(
          'id_aluno, numero_aluno, nome_completo, setor, categoria_usuario, nivel, telefone, imagem_url, idade',
        )
        .order('id_aluno', ascending: true);

    return (response as List)
        .map((item) => AlunoRecord.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> registrarExclusaoEDeletar({
    required AlunoRecord aluno,
    required String motivoExclusao,
  }) async {
    await _supabase.from('logs').insert({
      'id_aluno': aluno.idAluno,
      'numero_aluno': aluno.numeroAluno,
      'nome_completo': aluno.nomeCompleto,
      'setor': aluno.setor,
      'categoria_usuario': aluno.categoriaUsuario,
      'nivel': aluno.nivel,
      'telefone': aluno.telefone,
      'imagem_url': aluno.imagemUrl,
      'idade': aluno.idade,
      'motivo_exclusao': motivoExclusao,
      'data_exclusao': DateTime.now().toIso8601String(),
    });

    await _supabase.from('alunos').delete().eq('id_aluno', aluno.idAluno);
  }
}
