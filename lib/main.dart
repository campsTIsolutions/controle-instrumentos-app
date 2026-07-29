import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/theme.dart';
import 'features/alunos/alunos_page.dart';
import 'features/chamada/tela_anual.dart';
import 'features/historico/historico_page.dart';
import 'features/login/login_page.dart';
import 'features/instrumentos/ui/instrumentos_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BootstrapApp());
}

class BootstrapApp extends StatelessWidget {
  const BootstrapApp({super.key});

  Future<bool> _initialize() async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Supabase nao configurado. Rode com '
        '--dart-define=SUPABASE_URL=... '
        '--dart-define=SUPABASE_ANON_KEY=...',
      );
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );

    final session = Supabase.instance.client.auth.currentSession;
    return session != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Falha ao iniciar o app:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        return MyApp(hasSession: snapshot.data ?? false);
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.hasSession});

  final bool hasSession;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Instrumentos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routes: {
        '/instrumentos': (_) => const InstrumentosPage(),
        '/alunos': (_) => const AlunosPage(),
        '/chamada': (_) => const TelaAnual(),
        '/historico': (_) => const HistoricoPage(),
      },
      home: hasSession ? const InstrumentosPage() : const LoginPage(),
    );
  }
}
