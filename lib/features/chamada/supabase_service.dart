// lib/features/chamada/supabase_service.dart
// Camada de acesso ao Supabase — chamadas, alunos e aulas

import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class SupabaseService {
  static final _db = Supabase.instance.client;

  // ─── ALUNOS ───────────────────────────────────────────────────────────────

  /// Busca todos os alunos da tabela `alunos`
  static Future<List<StudentRecord>> fetchAlunos() async {
    final data = await _db
        .from('alunos')
        .select('id_aluno, nome_completo')
        .order('nome_completo');

    return (data as List)
        .map((row) => StudentRecord(
              idAluno: row['id_aluno'] as int,
              name: row['nome_completo'] as String,
              attendance: {},
            ))
        .toList();
  }

  /// Insere um novo aluno na tabela `alunos`
  static Future<StudentRecord> inserirAluno({
    required String nomeCompleto,
    String? setor,
    String? nivel,
    String? telefone,
  }) async {
    final response = await _db
        .from('alunos')
        .insert({
          'nome_completo': nomeCompleto,
          if (setor != null) 'setor': setor,
          if (nivel != null) 'nivel': nivel,
          if (telefone != null) 'telefone': telefone,
        })
        .select('id_aluno, nome_completo')
        .single();

    return StudentRecord(
      idAluno: response['id_aluno'] as int,
      name: response['nome_completo'] as String,
      attendance: {},
    );
  }

  /// Remove um aluno da tabela `alunos`
  static Future<void> deletarAluno(int idAluno) async {
    await _db.from('alunos').delete().eq('id_aluno', idAluno);
  }

  // ─── AULAS ────────────────────────────────────────────────────────────────

  /// Busca todas as aulas de um mês/ano filtrando por intervalo de data
  static Future<List<AulaRecord>> fetchAulas({
    required int ano,
    required int mes,
  }) async {
    final inicio = DateTime(ano, mes, 1).toIso8601String().split('T').first;
    final fim =
        DateTime(ano, mes + 1, 0).toIso8601String().split('T').first;

    final data = await _db
        .from('aulas')
        .select('id, data')
        .gte('data', inicio)
        .lte('data', fim)
        .order('data');

    return (data as List)
        .map((row) => AulaRecord(
              id: row['id'] as String,
              data: DateTime.parse(row['data'] as String),
            ))
        .toList();
  }

  /// Insere uma nova aula na tabela `aulas`
  static Future<AulaRecord> inserirAula({
    required DateTime data,
  }) async {
    final response = await _db
        .from('aulas')
        .insert({
          'data': data.toIso8601String().split('T').first,
        })
        .select('id, data')
        .single();

    return AulaRecord(
      id: response['id'] as String,
      data: DateTime.parse(response['data'] as String),
    );
  }

  /// Remove uma aula e suas chamadas da tabela `aulas`
  /// (as chamadas são deletadas em cascata se configurado no Supabase,
  ///  caso contrário são deletadas explicitamente aqui)
  static Future<void> deletarAula(String aulaId) async {
    // Remove as chamadas vinculadas antes de deletar a aula
    await _db.from('chamadas').delete().eq('aula_id', aulaId);
    await _db.from('aulas').delete().eq('id', aulaId);
  }

  // ─── CHAMADAS ─────────────────────────────────────────────────────────────

  /// Busca as chamadas de uma aula específica
  static Future<List<ChamadaRecord>> fetchChamadas(String aulaId) async {
    final data = await _db
        .from('chamadas')
        .select('id, aula_id, id_aluno, status, comprovante_url')
        .eq('aula_id', aulaId);

    return (data as List)
        .map((row) => ChamadaRecord(
              id: row['id'] as String,
              aulaId: row['aula_id'] as String,
              idAluno: row['id_aluno'] as int,
              status: _parseStatus(row['status'] as String?),
              comprovanteUrl: row['comprovante_url'] as String?,
            ))
        .toList();
  }

  /// Salva (upsert) a chamada de um aluno em uma aula
  static Future<void> salvarChamada({
    required String aulaId,
    required int idAluno,
    required AttendanceStatus status,
    String? comprovanteUrl,
  }) async {
    await _db.from('chamadas').upsert(
      {
        'aula_id': aulaId,
        'id_aluno': idAluno,
        'status': _statusToString(status),
        if (comprovanteUrl != null) 'comprovante_url': comprovanteUrl,
      },
      onConflict: 'aula_id,id_aluno',
    );
  }

  /// Salva todas as chamadas de uma aula de uma vez (batch upsert)
  static Future<void> salvarTodasChamadas({
    required String aulaId,
    required List<StudentRecord> alunos,
    required DateTime data,
  }) async {
    final rows = alunos.map((aluno) {
      final statuses =
          aluno.attendance[data] ?? [AttendanceStatus.none];
      final status = statuses.isNotEmpty
          ? statuses.first
          : AttendanceStatus.none;
      return {
        'aula_id': aulaId,
        'id_aluno': aluno.idAluno,
        'status': _statusToString(status),
        'comprovante_url': aluno.atestadoNome[data],
      };
    }).toList();

    await _db
        .from('chamadas')
        .upsert(rows, onConflict: 'aula_id,id_aluno');
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static AttendanceStatus _parseStatus(String? s) {
    switch (s) {
      case 'presente':
        return AttendanceStatus.presente;
      case 'atestado':
        return AttendanceStatus.atestado;
      case 'falta':
        return AttendanceStatus.falta;
      default:
        return AttendanceStatus.none;
    }
  }

  static String _statusToString(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.presente:
        return 'presente';
      case AttendanceStatus.atestado:
        return 'atestado';
      case AttendanceStatus.falta:
        return 'falta';
      case AttendanceStatus.none:
        return 'none';
    }
  }
}
