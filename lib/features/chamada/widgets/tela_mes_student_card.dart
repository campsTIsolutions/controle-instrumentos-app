import 'package:controle_instrumentos/features/chamada/models.dart';
import 'package:controle_instrumentos/features/chamada/atestado_utils.dart';
import 'package:flutter/material.dart';

class CardAlunoMes extends StatelessWidget {
  const CardAlunoMes({
    super.key,
    required this.student,
    required this.dates,
    required this.aulasDoMes,
    required this.onSetStatus,
    required this.onAnexarAtestado,
    required this.soData,
  });

  final StudentRecord student;
  final List<DateTime> dates;
  final List<AulaRecord> aulasDoMes;
  final void Function(DateTime date, AttendanceStatus status) onSetStatus;
  final void Function(DateTime date) onAnexarAtestado;
  final DateTime Function(DateTime) soData;

  static const _verde = Color(0xFF4CAF50);
  static const _amarelo = Color(0xFFFFC107);
  static const _vermelho = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(
                  0xFF1976D2,
                ).withValues(alpha: 0.12),
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
              ...dates.map((d) {
                final status =
                    student.attendance[soData(d)]?.first ??
                    AttendanceStatus.none;
                if (status == AttendanceStatus.none) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(
                    width: 26,
                    height: 20,
                    decoration: BoxDecoration(
                      color: status.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      status.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          if (dates.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            ...dates.map((date) {
              final dataKey = soData(date);
              final status =
                  student.attendance[dataKey]?.first ?? AttendanceStatus.none;
              final temAtestado = status == AttendanceStatus.A;
              final arquivoNomeRef = student.atestadoNome[dataKey];
              final arquivoNome = arquivoNomeRef == null
                  ? null
                  : extrairNomeArquivoAtestado(arquivoNomeRef);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        BotaoStatusMes(
                          label: 'Presente',
                          cor: _verde,
                          selecionado: status == AttendanceStatus.P,
                          onTap: () => onSetStatus(date, AttendanceStatus.P),
                        ),
                        const SizedBox(width: 6),
                        BotaoStatusMes(
                          label: 'Falta',
                          cor: _vermelho,
                          selecionado: status == AttendanceStatus.F,
                          onTap: () => onSetStatus(date, AttendanceStatus.F),
                        ),
                        const SizedBox(width: 6),
                        BotaoStatusMes(
                          label: 'Atestado',
                          cor: _amarelo,
                          selecionado: temAtestado,
                          onTap: () => onSetStatus(date, AttendanceStatus.A),
                        ),
                      ],
                    ),
                    if (temAtestado) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => onAnexarAtestado(date),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _amarelo.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _amarelo.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                arquivoNome != null
                                    ? Icons.check_circle_outline
                                    : Icons.attach_file,
                                size: 14,
                                color: arquivoNome != null
                                    ? _verde
                                    : Colors.black45,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                arquivoNome ?? 'Anexar comprovante',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: arquivoNome != null
                                      ? _verde
                                      : Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class BotaoStatusMes extends StatelessWidget {
  const BotaoStatusMes({
    super.key,
    required this.label,
    required this.cor,
    required this.selecionado,
    required this.onTap,
  });

  final String label;
  final Color cor;
  final bool selecionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selecionado ? cor : cor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selecionado ? cor : cor.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selecionado ? Colors.white : cor,
            ),
          ),
        ),
      ),
    );
  }
}
