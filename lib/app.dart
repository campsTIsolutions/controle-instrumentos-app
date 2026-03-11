import 'package:flutter/material.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/instrumentos_page.dart';
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: const InstrumentosPage(),
    );
  }
}