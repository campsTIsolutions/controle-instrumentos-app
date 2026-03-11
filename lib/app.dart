import 'package:flutter/material.dart';
import 'features/auth/ui/auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('MyApp: build');
    return MaterialApp(
      title: 'Controle de Instrumentos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(), // <- aqui
    );
  }
}
