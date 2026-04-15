// lib/features/chamada/widgets.dart
// Widgets visuais reutilizáveis — sem lógica de negócio

import 'package:flutter/material.dart';
import 'models.dart';

// ─── Cabeçalho de data (coluna da grade) ─────────────────────────────────────

class DateHeaderCell extends StatelessWidget {
  final DateTime date;
  final double width;

  const DateHeaderCell({super.key, required this.date, required this.width});

  @override
  Widget build(BuildContext context) {
    final dia  = date.day.toString().padLeft(2, '0');
    final mes  = date.month.toString().padLeft(2, '0');
    final ano  = date.year.toString();

    return SizedBox(
      width: width,
      height: 56,
      child: Center(
        child: Text(
          '$dia/$mes/\n$ano',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

// ─── Célula de nome do aluno ──────────────────────────────────────────────────

class NameCell extends StatelessWidget {
  final String name;
  final int rowSpanCount;

  const NameCell({super.key, required this.name, required this.rowSpanCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.0 * rowSpanCount,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pill de status (P / A / F) na grade ─────────────────────────────────────

class StatusCell extends StatelessWidget {
  final AttendanceStatus status;

  const StatusCell({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isEmpty = status == AttendanceStatus.none;

    return SizedBox(
      height: 44,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 38,
          height: 28,
          decoration: BoxDecoration(
            color: isEmpty ? Colors.transparent : status.backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              isEmpty ? '' : status.label,
              style: TextStyle(
                color: status.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Legenda inferior ─────────────────────────────────────────────────────────

class AttendanceLegend extends StatelessWidget {
  const AttendanceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: AttendanceStatus.P.backgroundColor, label: 'P (P)'),
          const SizedBox(width: 20),
          _LegendItem(color: AttendanceStatus.A.backgroundColor, label: 'A (A)'),
          const SizedBox(width: 20),
          _LegendItem(color: AttendanceStatus.F.backgroundColor,    label: 'F (F)'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}

// ─── Botão de status (Presente / Falta / Atestado) na tela de detalhe ────────

class BotaoStatus extends StatelessWidget {
  final String label;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  const BotaoStatus({
    super.key,
    required this.label,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selecionado ? cor : cor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selecionado ? cor : cor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selecionado ? Colors.white : cor,
            ),
          ),
        ),
      ),
    );
  }
}