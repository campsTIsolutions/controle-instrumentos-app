import 'package:controle_instrumentos/shared/widgets/inline_badge.dart';
import 'package:controle_instrumentos/shared/widgets/person_avatar.dart';
import 'package:controle_instrumentos/shared/widgets/tag_chip.dart';
import 'package:controle_instrumentos/shared/widgets/table_action_button.dart';
import 'package:controle_instrumentos/shared/widgets/top_rounded_panel.dart';
import 'package:flutter/material.dart';

class AlunosCards extends StatelessWidget {
  const AlunosCards({
    super.key,
    required this.alunos,
    required this.currentPage,
    required this.itensPorPagina,
    required this.onEditar,
    required this.onDeletar,
  });

  final List<Map<String, dynamic>> alunos;
  final int currentPage;
  final int itensPorPagina;
  final void Function(Map<String, dynamic>) onEditar;
  final void Function(Map<String, dynamic>) onDeletar;

  @override
  Widget build(BuildContext context) {
    return TopRoundedPanel(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: alunos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final aluno = alunos[i];
          final numero = (currentPage - 1) * itensPorPagina + i + 1;
          return _AlunoCard(
            numero: numero,
            aluno: aluno,
            onEditar: () => onEditar(aluno),
            onDeletar: () => onDeletar(aluno),
          );
        },
      ),
    );
  }
}

class _AlunoCard extends StatelessWidget {
  const _AlunoCard({
    required this.numero,
    required this.aluno,
    required this.onEditar,
    required this.onDeletar,
  });

  final int numero;
  final Map<String, dynamic> aluno;
  final VoidCallback onEditar;
  final VoidCallback onDeletar;

  @override
  Widget build(BuildContext context) {
    final imagemUrl = aluno['imagem_url'] as String?;
    final idade = aluno['idade'];

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
            backgroundColor: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
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
                        aluno['nome_completo']?.toString() ?? '',
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
                      text: '#${aluno['numero_aluno']}',
                      backgroundColor: const Color(0xFFEFF6FF),
                      textColor: const Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (aluno['setor'] != null)
                      TagChip(
                        label: aluno['setor'],
                        backgroundColor: const Color(0xFFF3F4F6),
                        textColor: const Color(0xFF374151),
                      ),
                    if (aluno['categoria_usuario'] != null)
                      TagChip(
                        label: aluno['categoria_usuario'],
                        backgroundColor: const Color(0xFFEDE9FE),
                        textColor: const Color(0xFF5B21B6),
                      ),
                    if (aluno['nivel'] != null)
                      TagChip(
                        label: aluno['nivel'],
                        backgroundColor: const Color(0xFFECFDF5),
                        textColor: const Color(0xFF065F46),
                      ),
                    if (idade != null)
                      TagChip(
                        label: '$idade anos',
                        backgroundColor: const Color(0xFFFFF7ED),
                        textColor: const Color(0xFF9A3412),
                      ),
                  ],
                ),
                if (aluno['telefone'] != null &&
                    aluno['telefone'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone,
                        size: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        aluno['telefone'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              TableActionButton(
                icon: Icons.edit,
                color: const Color(0xFF2563EB),
                onTap: onEditar,
              ),
              const SizedBox(height: 6),
              TableActionButton(
                icon: Icons.delete,
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
