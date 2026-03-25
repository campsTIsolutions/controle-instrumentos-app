import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/instrumentos/ui/instrumentos_page.dart';
import 'features/login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D00FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: hasSession ? const InstrumentosPage() : const LoginPage(),
    );
  }
}
