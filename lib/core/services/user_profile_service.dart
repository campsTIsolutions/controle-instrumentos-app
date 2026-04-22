import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileService {
  UserProfileService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<String> resolveDisplayName() async {
    final user = _supabase.auth.currentUser ?? _supabase.auth.currentSession?.user;
    final userEmail = user?.email?.trim();
    final emailLogin = userEmail?.split('@').first.trim();
    String nomeUsuario = user?.userMetadata?['name']?.toString().trim() ?? '';

    if (userEmail != null && userEmail.isNotEmpty) {
      try {
        final usuarioPorEmail = await _supabase
            .from('usuarios')
            .select('nome_usuario')
            .eq('login', userEmail)
            .maybeSingle();

        final nomeBancoEmail = usuarioPorEmail?['nome_usuario']?.toString().trim();

        if (nomeBancoEmail != null && nomeBancoEmail.isNotEmpty) {
          nomeUsuario = nomeBancoEmail;
        } else if (emailLogin != null && emailLogin.isNotEmpty) {
          final usuarioPorLogin = await _supabase
              .from('usuarios')
              .select('nome_usuario')
              .eq('login', emailLogin)
              .maybeSingle();

          final nomeBancoLogin = usuarioPorLogin?['nome_usuario']?.toString().trim();
          if (nomeBancoLogin != null && nomeBancoLogin.isNotEmpty) {
            nomeUsuario = nomeBancoLogin;
          }
        }
      } catch (_) {
        // Mantém fallback local se houver falha de consulta.
      }
    }

    if (nomeUsuario.isEmpty) {
      nomeUsuario = emailLogin ?? userEmail ?? 'Usuario';
    }
    return nomeUsuario;
  }
}
