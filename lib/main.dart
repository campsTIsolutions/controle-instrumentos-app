import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/login/login_page.dart';
import 'features/instrumentos/ui/instrumentos_page.dart';
import 'features/instrumentos/ui/instrumentos_page.dart';

void main() async {
  // Garante a inicialização dos componentes do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa a conexão real com o seu banco de dados Supabase
  await Supabase.initialize(
    url: 'https://ylcfdbonhrvvbclinado.supabase.co',
    anonKey: 'sb_publishable_YopOGM9CpLfvJXXiKNTHJw_Tx1RtZDn',
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
      theme: ThemeData(
        // Tema configurado para combinar com o seu layout Dark/Roxo
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D00FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
