import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle Instrumentos',
      home: const Scaffold(
        body: Center(
          child: Text('App iniciado 🚀'),
        ),
      ),
    );
  }
}