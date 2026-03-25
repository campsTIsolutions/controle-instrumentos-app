import 'package:flutter/material.dart';

class InstrumentoDetalhePage extends StatelessWidget {
  final String nome;
  final String tipo;
  final String aluno;

  const InstrumentoDetalhePage({
    super.key,
    required this.nome,
    required this.tipo,
    required this.aluno,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Instrumento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nome,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            Text(
              'Tipo: $tipo',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),

            Text(
              'Aluno: $aluno',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}