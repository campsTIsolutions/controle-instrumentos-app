import 'package:flutter/material.dart';

import '../utils/historico_formatters.dart';

class HistoricoLogDetalhesDialog extends StatelessWidget {
  const HistoricoLogDetalhesDialog({super.key, required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final imagemUrl = log['imagem_url'] as String?;
    final motivo = log['motivo_exclusao']?.toString() ?? '-';
    final dataExclusao = formatarDataHistorico(log['data_exclusao']?.toString());

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalhes do Registro',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Informações do aluno desligado',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF2A2A3E),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imagemUrl != null && imagemUrl.isNotEmpty
                      ? Image.network(
                          imagemUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            color: Color(0xFF9CA3AF),
                            size: 32,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          color: Color(0xFF9CA3AF),
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log['nome_completo']?.toString() ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Nº ${log['numero_aluno'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFF2A2A3E)),
            const SizedBox(height: 16),
            _InfoGrid(log: log),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2A2A3E)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Motivo do Desligamento',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    motivo,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Desligado em $dataExclusao',
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A3E),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Fechar',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final itens = [
      _InfoItem(
        icone: Icons.group_outlined,
        label: 'Setor',
        valor: log['setor']?.toString() ?? '-',
      ),
      _InfoItem(
        icone: Icons.badge_outlined,
        label: 'Categoria',
        valor: log['categoria_usuario']?.toString() ?? '-',
      ),
      _InfoItem(
        icone: Icons.military_tech_outlined,
        label: 'Nível',
        valor: log['nivel']?.toString() ?? '-',
      ),
      _InfoItem(
        icone: Icons.cake_outlined,
        label: 'Idade',
        valor: log['idade'] != null ? '${log['idade']} anos' : '-',
      ),
      _InfoItem(
        icone: Icons.phone_outlined,
        label: 'Telefone',
        valor: log['telefone']?.toString().isNotEmpty == true
            ? log['telefone'].toString()
            : '-',
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: itens
          .map(
            (item) => SizedBox(
              width: (MediaQuery.of(context).size.width - 104) / 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icone, size: 16, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.valor,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icone,
    required this.label,
    required this.valor,
  });

  final IconData icone;
  final String label;
  final String valor;
}
