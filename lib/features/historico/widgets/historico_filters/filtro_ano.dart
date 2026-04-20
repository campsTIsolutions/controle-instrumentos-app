import 'package:flutter/material.dart';

class FiltroAno extends StatelessWidget {
  const FiltroAno({
    super.key,
    required this.anos,
    required this.anoSelecionado,
    required this.onChanged,
  });

  final List<int> anos;
  final int? anoSelecionado;
  final void Function(int?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ano',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AnoChip(
                  label: 'Todos',
                  selecionado: anoSelecionado == null,
                  onTap: () => onChanged(null),
                ),
                ...anos.map(
                  (ano) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _AnoChip(
                      label: '$ano',
                      selecionado: anoSelecionado == ano,
                      onTap: () => onChanged(ano),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnoChip extends StatelessWidget {
  const _AnoChip({
    required this.label,
    required this.selecionado,
    required this.onTap,
  });

  final String label;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selecionado
                ? const Color(0xFF1A1A2E)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selecionado ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
