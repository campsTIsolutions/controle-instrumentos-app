import 'package:controle_instrumentos/features/chamada/tela_chamada.dart';
import 'package:controle_instrumentos/features/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:controle_instrumentos/features/chamada/ui/presenca_page.dart';

void main() async {
  // Garante a inicialização dos componentes do Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa a conexão real com o seu banco de dados Supabase
  await Supabase.initialize(
    url: 'https://ylcfdbonhrvvbclinado.supabase.co',
    anonKey: 'sb_publishable_YopOGM9CpLfvJXXiKNTHJw_Tx1RtZDn',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Instrumentos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema configurado para combinar com o seu layout Dark/Roxo
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D00FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CampsApp(),
    );
  }
}
