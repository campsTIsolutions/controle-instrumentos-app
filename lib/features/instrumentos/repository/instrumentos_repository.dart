import 'package:supabase_flutter/supabase_flutter.dart';

class InstrumentosRepository {
  InstrumentosRepository({SupabaseClient? client})
    : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  static const String _tabela = 'instrumentos';
  static const String _selectCampos =
      'id_instrumento, numero_patrimonio, nome_instrumento, disponivel, propriedade_instrumento, leva_instrumento, observacoes, imagem_url, id_aluno';

  Future<List<Map<String, dynamic>>> listarInstrumentos() async {
    final dynamic response = await _supabase
        .from(_tabela)
        .select(_selectCampos)
        .order('id_instrumento', ascending: true);

    final rawData = response is PostgrestResponse ? response.data : response;
    if (rawData is! List) {
      throw StateError(
        'Resposta inesperada ao listar instrumentos: ${rawData.runtimeType}',
      );
    }

    return rawData
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> criarInstrumento(Map<String, dynamic> dados) async {
    await _supabase.from(_tabela).insert(dados);
  }

  Future<void> atualizarInstrumento({
    required dynamic idInstrumento,
    required Map<String, dynamic> dados,
  }) async {
    await _supabase
        .from(_tabela)
        .update(dados)
        .eq('id_instrumento', idInstrumento);
  }

  Future<void> eliminarInstrumento(int id) async {
    await _supabase.from(_tabela).delete().eq('id_instrumento', id);
  }
}
