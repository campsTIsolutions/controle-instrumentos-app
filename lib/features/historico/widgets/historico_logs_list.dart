import 'package:controle_instrumentos/features/historico/widgets/historico_logs_list/historico_logs_cards.dart';
import 'package:controle_instrumentos/features/historico/widgets/historico_logs_list/historico_logs_table.dart';
import 'package:flutter/material.dart';

class HistoricoLogsList extends StatelessWidget {
  const HistoricoLogsList({
    super.key,
    required this.logs,
    required this.currentPage,
    required this.itensPorPagina,
    required this.isTablet,
    required this.onVerDetalhes,
    required this.onDeletar,
  });

  final List<Map<String, dynamic>> logs;
  final int currentPage;
  final int itensPorPagina;
  final bool isTablet;
  final void Function(Map<String, dynamic>) onVerDetalhes;
  final void Function(Map<String, dynamic>) onDeletar;

  @override
  Widget build(BuildContext context) {
    return isTablet
        ? HistoricoLogsTable(
            logs: logs,
            currentPage: currentPage,
            itensPorPagina: itensPorPagina,
            onVerDetalhes: onVerDetalhes,
            onDeletar: onDeletar,
          )
        : HistoricoLogsCards(
            logs: logs,
            currentPage: currentPage,
            itensPorPagina: itensPorPagina,
            onVerDetalhes: onVerDetalhes,
            onDeletar: onDeletar,
          );
  }
}
