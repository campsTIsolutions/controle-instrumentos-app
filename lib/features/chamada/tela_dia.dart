// lib/features/chamada/tela_dia.dart
// Tela de detalhe de um dia: lista de alunos com botões P / F / A

import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';
import 'tela_atestado.dart';

class TelaDia extends StatefulWidget {
  final DateTime data;
  final List<StudentRecord> students;
  final VoidCallback onChanged;

  const TelaDia({
    super.key,
    required this.data,
    required this.students,
    required this.onChanged,
  });

  @override
  State<TelaDia> createState() => _TelaDiaState();
}

class _TelaDiaState extends State<TelaDia> {
  // ── Alterar status de um aluno/aula ──────────────────────────────────────
  void _setStatus(int si, int ri, AttendanceStatus novoStatus) {
    setState(() {
      widget.students[si].attendance[widget.data]![ri] = novoStatus;
      // Limpa o atestado se o status deixar de ser "atestado"
      if (novoStatus != AttendanceStatus.atestado) {
        widget.students[si].atestadoNome[widget.data] = null;
      }
    });
    widget.onChanged();
  }

  // ── Abrir tela de atestado ────────────────────────────────────────────────
  void _abrirAtestado(int si) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaAtestado(
          student: widget.students[si],
          data: widget.data,
          onAnexado: (nomeArquivo) {
            setState(() {
              widget.students[si].atestadoNome[widget.data] = nomeArquivo;
            });
            widget.onChanged();
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chamada do dia',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              _formatDate(widget.data),
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.students.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, si) => _CardAluno(
          student: widget.students[si],
          data: widget.data,
          onSetStatus: (ri, status) => _setStatus(si, ri, status),
          onAbrirAtestado: () => _abrirAtestado(si),
        ),
      ),
    );
  }
}

// ─── Card de aluno (extraído para manter o build limpo) ──────────────────────

class _CardAluno extends StatelessWidget {
  final StudentRecord student;
  final DateTime data;
  final void Function(int ri, AttendanceStatus status) onSetStatus;
  final VoidCallback onAbrirAtestado;

  const _CardAluno({
    required this.student,
    required this.data,
    required this.onSetStatus,
    required this.onAbrirAtestado,
  });

  @override
  Widget build(BuildContext context) {
    final statuses  = student.attendance[data] ?? [AttendanceStatus.none];
    final temAtestado = statuses.contains(AttendanceStatus.atestado);
    final arquivoNome = student.atestadoNome[data];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha do nome + badges ──────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1976D2).withOpacity(0.12),
                child: Text(
                  student.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1976D2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Mini-pills com o status atual
              ...statuses.where((s) => s != AttendanceStatus.none).map((s) =>
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 28, height: 20,
                    decoration: BoxDecoration(
                      color: s.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )),
            ],
          ),
          const SizedBox(height: 14),

          // ── Botões P / F / A por aula ───────────────────────────────────
          ...List.generate(statuses.length, (ri) => Padding(
            padding: EdgeInsets.only(bottom: ri < statuses.length - 1 ? 10 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (statuses.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Aula ${ri + 1}',
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ),
                Row(
                  children: [
                    BotaoStatus(
                      label: 'Presente',
                      cor: const Color(0xFF4CAF50),
                      selecionado: statuses[ri] == AttendanceStatus.presente,
                      onTap: () => onSetStatus(ri, AttendanceStatus.presente),
                    ),
                    const SizedBox(width: 8),
                    BotaoStatus(
                      label: 'Falta',
                      cor: const Color(0xFFE53935),
                      selecionado: statuses[ri] == AttendanceStatus.falta,
                      onTap: () => onSetStatus(ri, AttendanceStatus.falta),
                    ),
                    const SizedBox(width: 8),
                    BotaoStatus(
                      label: 'Atestado',
                      cor: const Color(0xFFFFC107),
                      selecionado: statuses[ri] == AttendanceStatus.atestado,
                      onTap: () => onSetStatus(ri, AttendanceStatus.atestado),
                    ),
                  ],
                ),
              ],
            ),
          )),

          // ── Atalho para atestado ─────────────────────────────────────────
          if (temAtestado) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  arquivoNome != null
                      ? Icons.check_circle_outline
                      : Icons.attachment,
                  size: 16,
                  color: arquivoNome != null
                      ? const Color(0xFF4CAF50)
                      : Colors.black45,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    arquivoNome ?? 'Nenhum comprovante anexado',
                    style: TextStyle(
                      fontSize: 12,
                      color: arquivoNome != null
                          ? const Color(0xFF4CAF50)
                          : Colors.black45,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onAbrirAtestado,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFC107),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    arquivoNome != null ? 'Trocar' : 'Anexar',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
