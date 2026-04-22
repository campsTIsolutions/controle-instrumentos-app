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
  runApp(MyApp(hasSession: session != null));
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
