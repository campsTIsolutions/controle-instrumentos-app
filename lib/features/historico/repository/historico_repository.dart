import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/historico_log_record.dart';

class HistoricoRepository {
  HistoricoRepository({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<List<HistoricoLogRecord>> listarLogs() async {
    final response = await _supabase
        .from('logs')
        .select(
          'id_log, id_aluno, numero_aluno, nome_completo, setor, '
          'categoria_usuario, nivel, telefone, imagem_url, idade, '
          'motivo_exclusao, data_exclusao',
        )
        .order('data_exclusao', ascending: false);

    return (response as List)
        .map(
          (item) => HistoricoLogRecord.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> deletarLog(int idLog) async {
    await _supabase.from('logs').delete().eq('id_log', idLog);
  }
}
