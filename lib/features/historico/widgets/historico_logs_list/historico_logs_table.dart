import 'package:controle_instrumentos/features/historico/utils/historico_formatters.dart';
import 'package:controle_instrumentos/shared/widgets/person_avatar.dart';
import 'package:controle_instrumentos/shared/widgets/table_action_button.dart';
import 'package:controle_instrumentos/shared/widgets/top_rounded_panel.dart';
import 'package:flutter/material.dart';

class HistoricoLogsTable extends StatelessWidget {
  const HistoricoLogsTable({
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
      child: Column(
        children: [
          const _TabelaHeader(),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final log = logs[i];
              final numero = (currentPage - 1) * itensPorPagina + i + 1;
              return _TabelaLinha(
                numero: numero,
                log: log,
                onVerDetalhes: () => onVerDetalhes(log),
                onDeletar: () => onDeletar(log),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TabelaHeader extends StatelessWidget {
  const _TabelaHeader();

  static const _s = TextStyle(
    fontWeight: FontWeight.w600,
    color: Color(0xFF6B7280),
    fontSize: 12,
  );

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: _s)),
          SizedBox(width: 44, child: Text('Foto', style: _s)),
          SizedBox(width: 48, child: Text('Nº', style: _s)),
          SizedBox(width: 140, child: Text('Nome', style: _s)),
          SizedBox(width: 70, child: Text('Setor', style: _s)),
          SizedBox(width: 90, child: Text('Categoria', style: _s)),
          SizedBox(width: 120, child: Text('Motivo', style: _s)),
          Expanded(child: Text('Data Exclusão', style: _s)),
          SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _TabelaLinha extends StatelessWidget {
  const _TabelaLinha({
    required this.numero,
    required this.log,
    required this.onVerDetalhes,
    required this.onDeletar,
  });

  final int numero;
  final Map<String, dynamic> log;
  final VoidCallback onVerDetalhes;
  final VoidCallback onDeletar;

  static const _c = TextStyle(fontSize: 12, color: Color(0xFF111827));

  @override
  Widget build(BuildContext context) {
    final imagemUrl = log['imagem_url'] as String?;
    final motivo = log['motivo_exclusao']?.toString() ?? '-';
    final dataExclusao = formatarDataHistorico(
      log['data_exclusao']?.toString(),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$numero',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ),
          SizedBox(
            width: 44,
            child: PersonAvatar(
              imageUrl: imagemUrl,
              size: 32,
              radius: 6,
              backgroundColor: const Color(0xFFFEF2F2),
              iconColor: const Color(0xFFB91C1C),
              iconSize: 16,
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(log['numero_aluno']?.toString() ?? '', style: _c),
          ),
          SizedBox(
            width: 140,
            child: Text(
              log['nome_completo']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(log['setor']?.toString() ?? '', style: _c),
          ),
          SizedBox(
            width: 90,
            child: Text(
              log['categoria_usuario']?.toString() ?? '',
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 120,
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
          Expanded(
            child: Text(
              dataExclusao,
              style: _c,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 72,
            child: Row(
              children: [
                TableActionButton(
                  icon: Icons.visibility_outlined,
                  color: const Color(0xFF2563EB),
                  onTap: onVerDetalhes,
                ),
                const SizedBox(width: 6),
                TableActionButton(
                  icon: Icons.delete_outline,
                  color: const Color(0xFFB91C1C),
                  onTap: onDeletar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
