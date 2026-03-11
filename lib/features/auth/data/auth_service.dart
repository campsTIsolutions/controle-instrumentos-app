import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _auth = Supabase.instance.client.auth;
  static final _db = Supabase.instance.client;

  /// Sign in com email e senha (usa Supabase Auth)
  static Future<void> signInWithEmail(String email, String password) {
    return _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up: cria em auth.users E insere em usuarios
  static Future<void> signUpWithEmail(
    String email,
    String password, {
    String? nomeUsuario,
  }) async {
    // 1. Cria em auth.users
    final authResponse = await _auth.signUp(
      email: email,
      password: password,
    );

    final userId = authResponse.user?.id;
    if (userId == null) {
      throw Exception('Falha ao criar usuário');
    }

    // 2. Insere em usuarios
    try {
      await _db.from('usuarios').insert({
        'id_usuario': userId,
        'nome_usuario': nomeUsuario ?? email.split('@')[0],
        'login': email,
        'tipo_usuario': 'user',
      });
    } catch (e) {
      // Se falhar ao inserir em usuarios, tenta deletar de auth.users
      await _auth.admin.deleteUser(userId);
      throw Exception('Falha ao criar perfil do usuário: $e');
    }
  }

  /// Sign out (logout)
  static Future<void> signOut() => _auth.signOut();
}
