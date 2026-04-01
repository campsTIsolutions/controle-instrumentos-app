import 'dart:io';

import 'package:flutter/material.dart';

class InstrumentoDetalhePage extends StatelessWidget {
  const InstrumentoDetalhePage({
    super.key,
    required this.nome,
    required this.patrimonio,
    required this.status,
    required this.alunoNome,
    required this.propriedade,
    required this.levaInstrumento,
    required this.observacoes,
    required this.imageUrl,
  });

  final String nome;
  final String patrimonio;
  final String status;
  final String alunoNome;
  final String propriedade;
  final bool levaInstrumento;
  final String observacoes;
  final String imageUrl;

  Widget _buildImage() {
    if (imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFFE5E7EB),
        child: const Center(
          child: Icon(Icons.music_note, size: 52, color: Color(0xFF6B7280)),
        ),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFE5E7EB),
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 52,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return Image.file(
      File(imageUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFE5E7EB),
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 52,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '-' : value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do Instrumento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 220,
                child: _buildImage(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              nome,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _info('Patrimonio', patrimonio),
            _info('Status', status),
            _info('Aluno', alunoNome.isEmpty ? 'Sem aluno vinculado' : alunoNome),
            _info('Propriedade', propriedade),
            _info('Leva instrumento', levaInstrumento ? 'Sim' : 'Nao'),
            _info(
              'Observacoes',
              observacoes.isEmpty ? 'Sem observacoes' : observacoes,
            ),
            _info(
              'Referencia da foto',
              imageUrl.isEmpty ? 'Sem imagem cadastrada' : imageUrl,
            ),
          ],
        ),
      ),
    );
  }
}
