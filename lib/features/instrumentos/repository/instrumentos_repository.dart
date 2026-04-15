import 'package:supabase_flutter/supabase_flutter.dart';
import '/models/instrumentos_model.dart';

class InstrumentosRepository {
  // Aceder à instância do cliente Supabase
  final _supabase = Supabase.instance.client;
  final String _tabela = 'instrumentos'; // Nome da tabela no supa

  // 1. READ - Listar todos os instrumentos
  Future<List<Instrumentos>> listarInstrumentos() async {
    try {
      final data = await _supabase
          .from(_tabela)
          .select()
          .order('nome_instrumento', ascending: true); // Organiza por nome
      
      return (data as List).map((item) => Instrumentos.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Erro ao listar instrumentos: $e');
    }
  }

  // 2. CREATE - Inserir um novo instrumento
  Future<void> criarInstrumento(Instrumentos instrumento) async {
    try {
      await _supabase.from(_tabela).insert(instrumento.toJson());
    } catch (e) {
      throw Exception('Erro ao criar instrumento: $e');
    }
  }

  // 3. UPDATE - Atualizar dados de um instrumento existente
  Future<void> atualizarInstrumento(Instrumentos instrumento) async {
    try {
      await _supabase
          .from(_tabela)
          .update(instrumento.toJson())
          .eq('id_instrumento', instrumento.id_instrumento!); 
    } catch (e) {
      throw Exception('Erro ao atualizar instrumento: $e');
    }
  }

  // 4. DELETE - Remover um instrumento da base de dados
  Future<void> eliminarInstrumento(int id) async {
    try {
      await _supabase
          .from(_tabela)
          .delete()
          .eq('id_instrumento', id);
    } catch (e) {
      throw Exception('Erro ao eliminar instrumento: $e');
    }
  }

  Future<List<Instrumentos>> listarTodos() async {
    return listarInstrumentos();
  }

  Future<void> eliminar(int i) async {}
}
