import 'package:supabase_flutter/supabase_flutter.dart';

class InstrumentsRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchInstrumentos() async {
    final data = await client
        .from('instrumentos')
        .select(
          'id_instrumento, numero_patrimonio, nome_instrumento, disponivel, propriedade_instrumento, leva_instrumento, observacoes, imagem_url',
        )
        .order('id_instrumento', ascending: true);

    final lista = List<Map<String, dynamic>>.from(
      (data as List).map((item) => Map<String, dynamic>.from(item as Map)),
    );

    return lista;
  }
}
