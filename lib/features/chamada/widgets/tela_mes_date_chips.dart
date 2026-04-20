import 'package:flutter/material.dart';

class ChipDataMes extends StatelessWidget {
  const ChipDataMes({
    super.key,
    required this.dia,
    required this.mes,
    required this.cor,
    required this.onExcluir,
  });

  final int dia;
  final int mes;
  final Color cor;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.30), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${dia.toString().padLeft(2, '0')}/${mes.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onExcluir,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.remove, size: 12, color: cor),
            ),
          ),
        ],
      ),
    );
  }
}

class ChipAdicionarMes extends StatelessWidget {
  const ChipAdicionarMes({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1976D2).withValues(alpha: 0.40),
            width: 0.8,
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: Color(0xFF1976D2)),
            SizedBox(width: 4),
            Text(
              '+ data',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
