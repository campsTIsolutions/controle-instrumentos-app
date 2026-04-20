import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/aluno_record.dart';

abstract class AlunosRepositoryContract {
  Future<AlunosPageResult> listarAlunosPaginados({
    required int page,
    required int itemsPerPage,
    String query = '',
    List<String> categorias = const [],
    List<String> setores = const [],
    bool ordenarAlfabetico = false,
  });

  Future<void> salvarAluno({required Map<String, dynamic> dados, int? idAluno});

  Future<String> uploadFotoAluno({
    required List<int> bytes,
    required String originalFileName,
  });

  Future<void> registrarExclusaoEDeletar({
    required AlunoRecord aluno,
    required String motivoExclusao,
  });
}

class AlunosPageResult {
  const AlunosPageResult({
    required this.items,
    required this.total,
    required this.page,
  });

  final List<AlunoRecord> items;
  final int total;
  final int page;
}

class AlunosRepository implements AlunosRepositoryContract {
  AlunosRepository({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const _selectFields =
      'id_aluno, numero_aluno, nome_completo, setor, categoria_usuario, nivel, telefone, imagem_url, idade';

  @override
  Future<AlunosPageResult> listarAlunosPaginados({
    required int page,
    required int itemsPerPage,
    String query = '',
    List<String> categorias = const [],
    List<String> setores = const [],
    bool ordenarAlfabetico = false,
  }) async {
    final normalizedPage = page < 1 ? 1 : page;
    final from = (normalizedPage - 1) * itemsPerPage;
    final to = from + itemsPerPage - 1;

    final trimmedQuery = query.trim();

    dynamic dataRequest = _supabase.from('alunos').select(_selectFields);
    dataRequest = _applyFilters(
      request: dataRequest,
      trimmedQuery: trimmedQuery,
      categorias: categorias,
      setores: setores,
    );
    dataRequest = ordenarAlfabetico
        ? dataRequest.order('nome_completo', ascending: true)
        : dataRequest.order('id_aluno', ascending: true);

    final rows = List<Map<String, dynamic>>.from(
      await dataRequest.range(from, to) as List,
    );
    final items = rows.map(AlunoRecord.fromMap).toList(growable: false);
    final total = await _countAlunos(
      trimmedQuery: trimmedQuery,
      categorias: categorias,
      setores: setores,
    );

    return AlunosPageResult(items: items, total: total, page: normalizedPage);
  }

  Future<int> _countAlunos({
    required String trimmedQuery,
    required List<String> categorias,
    required List<String> setores,
  }) async {
    dynamic countRequest = _supabase.from('alunos').select('id_aluno');
    countRequest = _applyFilters(
      request: countRequest,
      trimmedQuery: trimmedQuery,
      categorias: categorias,
      setores: setores,
    );
    return await countRequest.count(CountOption.exact);
  }

  dynamic _applyFilters({
    required dynamic request,
    required String trimmedQuery,
    required List<String> categorias,
    required List<String> setores,
  }) {
    var next = request;

    if (trimmedQuery.isNotEmpty) {
      next = next.or(
        'nome_completo.ilike.%$trimmedQuery%,numero_aluno.ilike.%$trimmedQuery%',
      );
    }

    if (categorias.isNotEmpty) {
      next = next.inFilter('categoria_usuario', categorias);
    }

    if (setores.isNotEmpty) {
      next = next.inFilter('setor', setores);
    }

    return next;
  }

  @override
  Future<void> salvarAluno({
    required Map<String, dynamic> dados,
    int? idAluno,
  }) async {
    if (idAluno == null) {
      await _supabase.from('alunos').insert(dados);
      return;
    }

    await _supabase.from('alunos').update(dados).eq('id_aluno', idAluno);
  }

  @override
  Future<String> uploadFotoAluno({
    required List<int> bytes,
    required String originalFileName,
  }) async {
    final safeFileName = originalFileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(' ', '_');

    final objectPath = '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    await _supabase.storage
        .from('alunos-fotos')
        .uploadBinary(objectPath, Uint8List.fromList(bytes));

    return _supabase.storage.from('alunos-fotos').getPublicUrl(objectPath);
  }

  @override
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
