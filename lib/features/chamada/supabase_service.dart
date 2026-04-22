// lib/features/chamada/supabase_service.dart
// Camada de acesso ao Supabase — chamadas, alunos e aulas

import 'dart:typed_data';

import 'package:controle_instrumentos/core/config/storage_paths.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

class SupabaseService {
  static final _db = Supabase.instance.client;

  // ─── HELPER DE DATA ───────────────────────────────────────────────────────

  /// Normaliza qualquer DateTime para meia-noite LOCAL, sem fuso.
  static DateTime _soData(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ─── ALUNOS ───────────────────────────────────────────────────────────────

  static Future<List<StudentRecord>> fetchAlunos() async {
    final data = await _db
        .from('alunos')
        .select('id_aluno, nome_completo')
        .order('nome_completo');

    return (data as List)
        .map(
          (row) => StudentRecord(
            idAluno: row['id_aluno'] as int,
            name: row['nome_completo'] as String,
            attendance: {},
          ),
        )
        .toList();
  }

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

  static Future<void> deletarAluno(int idAluno) async {
    await _db.from('alunos').delete().eq('id_aluno', idAluno);
  }

  // ─── AULAS ────────────────────────────────────────────────────────────────

  static Future<List<AulaRecord>> fetchAulas({
    required int ano,
    required int mes,
  }) async {
    final inicio = DateTime(ano, mes, 1).toIso8601String().split('T').first;
    final fim = DateTime(ano, mes + 1, 0).toIso8601String().split('T').first;

    final data = await _db
        .from('aulas')
        .select('id, data')
        .gte('data', inicio)
        .lte('data', fim)
        .order('data');

    return (data as List)
        .map(
          (row) => AulaRecord(
            id: row['id'] as String,
            data: _soData(DateTime.parse(row['data'] as String)),
          ),
        )
        .toList();
  }

  static Future<AulaRecord> inserirAula({required DateTime data}) async {
    final response = await _db
        .from('aulas')
        .insert({'data': data.toIso8601String().split('T').first})
        .select('id, data')
        .single();

    return AulaRecord(
      id: response['id'] as String,
      data: _soData(DateTime.parse(response['data'] as String)),
    );
  }

  static Future<void> deletarAula(String aulaId) async {
    await _db.from('chamadas').delete().eq('aula_id', aulaId);
    await _db.from('aulas').delete().eq('id', aulaId);
  }

  // ─── CHAMADAS ─────────────────────────────────────────────────────────────

  static Future<List<ChamadaRecord>> fetchChamadas(String aulaId) async {
    final data = await _db
        .from('chamadas')
        .select('id, aula_id, id_aluno, status, comprovante_url')
        .eq('aula_id', aulaId);

    return (data as List)
        .map(
          (row) => ChamadaRecord(
            id: row['id'] as String,
            aulaId: row['aula_id'] as String,
            idAluno: row['id_aluno'] as int,
            status: _parseStatus(row['status'] as String?),
            comprovanteUrl: row['comprovante_url'] as String?,
          ),
        )
        .toList();
  }

  /// Salva (upsert) a chamada de um aluno.
  /// Se o status for 'none', DELETA a linha — nunca salva valor inválido.
  static Future<void> salvarChamada({
    required String aulaId,
    required int idAluno,
    required AttendanceStatus status,
    String? comprovanteUrl,
  }) async {
    if (status == AttendanceStatus.none) {
      await _db
          .from('chamadas')
          .delete()
          .eq('aula_id', aulaId)
          .eq('id_aluno', idAluno);
      return;
    }

    await _db.from('chamadas').upsert({
      'aula_id': aulaId,
      'id_aluno': idAluno,
      'status': _statusToString(status),
      'comprovante_url': comprovanteUrl,
    }, onConflict: 'aula_id,id_aluno');
  }

  /// Salva todas as chamadas em lote. Ignora alunos com status 'none'.
  static Future<void> salvarTodasChamadas({
    required String aulaId,
    required List<StudentRecord> alunos,
    required DateTime data,
  }) async {
    final dataKey = _soData(data);
    final rows = <Map<String, dynamic>>[];

    for (final aluno in alunos) {
      final statuses = aluno.attendance[dataKey] ?? [AttendanceStatus.none];
      final status = statuses.isNotEmpty
          ? statuses.first
          : AttendanceStatus.none;

      // NUNCA salva 'none' — viola a constraint chamadas_status_check
      if (status == AttendanceStatus.none) continue;

      rows.add({
        'aula_id': aulaId,
        'id_aluno': aluno.idAluno,
        'status': _statusToString(status),
        'comprovante_url': aluno.atestadoNome[dataKey],
      });
    }

    if (rows.isNotEmpty) {
      await _db.from('chamadas').upsert(rows, onConflict: 'aula_id,id_aluno');
    }
  }

  static Future<String> uploadComprovanteAtestado({
    required int idAluno,
    required DateTime data,
    required List<int> bytes,
    required String originalFileName,
  }) async {
    final safeFileName = originalFileName
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(' ', '_');

    final dataIso = _soData(data).toIso8601String().split('T').first;
    final objectPath = StoragePaths.atestadoObjectPath(
      idAluno: idAluno,
      dataIso: dataIso,
      safeFileName: safeFileName,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    );

    await _db.storage
        .from(StoragePaths.bucket)
        .uploadBinary(objectPath, Uint8List.fromList(bytes));

    return _db.storage.from(StoragePaths.bucket).getPublicUrl(objectPath);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static AttendanceStatus _parseStatus(String? s) {
    switch (s) {
      case 'P':
        return AttendanceStatus.P;
      case 'A':
        return AttendanceStatus.A;
      case 'F':
        return AttendanceStatus.F;
      default:
        return AttendanceStatus.none;
    }
  }

  static String _statusToString(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.P:
        return 'P';
      case AttendanceStatus.A:
        return 'A';
      case AttendanceStatus.F:
        return 'F';
      case AttendanceStatus.none:
        // Nunca deve chegar aqui — salvarChamada e salvarTodasChamadas filtram antes
        return 'P';
    }
  }
}
