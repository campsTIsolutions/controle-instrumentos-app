import 'dart:io';

import 'package:flutter/material.dart';

import 'instrumento_actionbuttom.dart';

class InstrumentoCard extends StatelessWidget {
  const InstrumentoCard({
    super.key,
    required this.nome,
    required this.patrimonio,
    required this.status,
    required this.alunoNome,
    required this.propriedade,
    required this.levaInstrumento,
    required this.observacoes,
    required this.imageUrl,
    this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final String nome;
  final String patrimonio;
  final String status;
  final String alunoNome;
  final String propriedade;
  final bool levaInstrumento;
  final String observacoes;
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Widget _buildImage() {
    if (imageUrl.trim().isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.music_note, size: 34, color: Color(0xFF6B7280)),
        ),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 34,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 34,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  bool get _estaDisponivel {
    final texto = status.trim().toLowerCase();
    return texto.startsWith('dispon');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 74,
                height: 74,
                child: _buildImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            nome,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$patrimonio',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _ChipInfo(
                          label: status,
                          cor: _estaDisponivel
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEE2E2),
                          textoCor: _estaDisponivel
                              ? const Color(0xFF065F46)
                              : const Color(0xFF991B1B),
                        ),
                        if (propriedade.trim().isNotEmpty)
                          _ChipInfo(
                            label: propriedade,
                            cor: const Color(0xFFF3F4F6),
                            textoCor: const Color(0xFF374151),
                          ),
                        _ChipInfo(
                          label:
                              levaInstrumento ? 'Leva instrumento' : 'No local',
                          cor: const Color(0xFFEDE9FE),
                          textoCor: const Color(0xFF5B21B6),
                        ),
                      ],
                    ),
                    if (observacoes.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.notes_rounded,
                              size: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              observacoes,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (alunoNome.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              alunoNome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
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
                  InstrumentoActionbuttom(
                    icone: Icons.edit,
                    cor: const Color(0xFF2563EB),
                    onTap: onEdit,
                  ),
                  const SizedBox(height: 6),
                  InstrumentoActionbuttom(
                    icone: Icons.delete,
                    cor: const Color(0xFFB91C1C),
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  const _ChipInfo({
    required this.label,
    required this.cor,
    required this.textoCor,
  });

  final String label;
  final Color cor;
  final Color textoCor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: textoCor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
