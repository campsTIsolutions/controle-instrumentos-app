import 'package:flutter/material.dart';

class InstrumentoCard extends StatelessWidget {
  final String nome;
  final String tipo;
  final String aluno;
  final VoidCallback? onTap;

  const InstrumentoCard({
    super.key,
    required this.nome,
    required this.tipo,
    required this.aluno,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
              const SizedBox(height: 4),
              const Divider(
                height: 1,
                thickness: 2,
              ),
              const SizedBox(height: 6),
              Text("Tipo: $tipo"),
              Text("Aluno: $aluno"),
            ],
          ),
        ),
      ),
    );
  }
}