import 'package:supabase_flutter/supabase_flutter.dart';

class InstrumentsRepository {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchInstrumentos() async {
    final data = await client
        .from('instrumentos')
        .select('*')
        .order('created_at', ascending: false);

    // supabase_flutter retorna List<dynamic>
    return (data as List).cast<Map<String, dynamic>>();
  }
}