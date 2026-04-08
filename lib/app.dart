import 'package:controle_instrumentos/features/chamada/tela_anual.dart';
import 'package:flutter/material.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/instrumentos_page.dart';
import 'package:controle_instrumentos/features/login/login_page.dart';
//import 'package:controle_instrumentos/lib/features/chamada/ui/presenca_page.dart';
import 'package:controle_instrumentos/features/chamada/supabase_service.dart';
import 'package:controle_instrumentos/features/chamada/models.dart';
import 'package:controle_instrumentos/features/chamada/tela_atestado.dart';
import 'package:controle_instrumentos/features/chamada/tela_dia.dart';
import 'package:controle_instrumentos/features/chamada/tela_mes.dart';
import 'package:controle_instrumentos/features/chamada/widgets.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const TelaAnual(),      
    );
  }
}