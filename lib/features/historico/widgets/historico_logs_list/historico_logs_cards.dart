import 'package:controle_instrumentos/features/historico/utils/historico_formatters.dart';
import 'package:controle_instrumentos/shared/widgets/inline_badge.dart';
import 'package:controle_instrumentos/shared/widgets/person_avatar.dart';
import 'package:controle_instrumentos/shared/widgets/tag_chip.dart';
import 'package:controle_instrumentos/shared/widgets/table_action_button.dart';
import 'package:controle_instrumentos/shared/widgets/top_rounded_panel.dart';
import 'package:flutter/material.dart';

class HistoricoLogsCards extends StatelessWidget {
  const HistoricoLogsCards({
    super.key,
    required this.logs,
    required this.currentPage,
    required this.itensPorPagina,
    required this.onVerDetalhes,
    required this.onDeletar,
  });

  final List<Map<String, dynamic>> logs;
  final int currentPage;
  final int itensPorPagina;
  final void Function(Map<String, dynamic>) onVerDetalhes;
  final void Function(Map<String, dynamic>) onDeletar;

  @override
  Widget build(BuildContext context) {
    return TopRoundedPanel(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final log = logs[i];
          final numero = (currentPage - 1) * itensPorPagina + i + 1;
          return _LogCard(
            numero: numero,
            log: log,
            onVerDetalhes: () => onVerDetalhes(log),
            onDeletar: () => onDeletar(log),
          );
        },
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({
    required this.numero,
    required this.log,
    required this.onVerDetalhes,
    required this.onDeletar,
  });

  final int numero;
  final Map<String, dynamic> log;
  final VoidCallback onVerDetalhes;
  final VoidCallback onDeletar;

  @override
  Widget build(BuildContext context) {
    final imagemUrl = log['imagem_url'] as String?;
    final motivo = log['motivo_exclusao']?.toString() ?? '-';
    final dataExclusao = formatarDataHistorico(
      log['data_exclusao']?.toString(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$numero',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          PersonAvatar(
            imageUrl: imagemUrl,
            size: 44,
            radius: 8,
            backgroundColor: const Color(0xFFFEF2F2),
            iconColor: const Color(0xFFB91C1C),
            iconSize: 24,
            margin: const EdgeInsets.only(right: 12),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        log['nome_completo']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InlineBadge(
                      text: '#${log['numero_aluno']}',
                      backgroundColor: const Color(0xFFF3F4F6),
                      textColor: const Color(0xFF6B7280),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (log['setor'] != null)
                      TagChip(
                        label: log['setor'],
                        backgroundColor: const Color(0xFFF3F4F6),
                        textColor: const Color(0xFF374151),
                      ),
                    if (log['categoria_usuario'] != null)
                      TagChip(
                        label: log['categoria_usuario'],
                        backgroundColor: const Color(0xFFEDE9FE),
                        textColor: const Color(0xFF5B21B6),
                      ),
                    if (log['nivel'] != null)
                      TagChip(
                        label: log['nivel'],
                        backgroundColor: const Color(0xFFECFDF5),
                        textColor: const Color(0xFF065F46),
                      ),
                    if (log['idade'] != null)
                      TagChip(
                        label: '${log['idade']} anos',
                        backgroundColor: const Color(0xFFFFF7ED),
                        textColor: const Color(0xFF9A3412),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 13,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        motivo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dataExclusao,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              TableActionButton(
                icon: Icons.visibility_outlined,
                color: const Color(0xFF2563EB),
                onTap: onVerDetalhes,
              ),
              const SizedBox(height: 6),
              TableActionButton(
                icon: Icons.delete_outline,
                color: const Color(0xFFB91C1C),
                onTap: onDeletar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
