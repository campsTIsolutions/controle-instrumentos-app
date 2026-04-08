import 'package:controle_instrumentos/features/chamada/tela_anual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:controle_instrumentos/features/chamada/supabase_service.dart';
import 'package:controle_instrumentos/features/chamada/models.dart';
import 'package:controle_instrumentos/features/chamada/tela_atestado.dart';
import 'package:controle_instrumentos/features/chamada/tela_dia.dart';
import 'package:controle_instrumentos/features/chamada/tela_mes.dart';
import 'package:controle_instrumentos/features/chamada/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

      // ── Localização em Português do Brasil ────────────────────────────────
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4D00FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TelaAnual(),
    );
  }
}
