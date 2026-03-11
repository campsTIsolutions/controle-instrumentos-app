import 'package:flutter/material.dart';

class InstrumentoCard extends StatelessWidget {

  final String nome;
  final String tipo;
  final String aluno;

  const InstrumentoCard({
    super.key,
    required this.nome,
    required this.tipo,
    required this.aluno,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            nome,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text("Tipo: $tipo"),

          Text("Aluno: $aluno"),

        ],
      ),
    );
  }
}