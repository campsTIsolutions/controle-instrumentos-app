// lib/features/chamada/tela_atestado.dart
// Tela dedicada ao comprovante de atestado médico
// Usa dart:html para seleção de arquivo no Flutter Web.
// Para mobile, substitua por image_picker ou file_picker.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/widgets/app_drawer.dart';
import 'models.dart';

class TelaAtestado extends StatefulWidget {
  final StudentRecord student;
  final DateTime data;

  /// Callback chamado ao confirmar o arquivo — passa o nome do arquivo
  final void Function(String nomeArquivo) onAnexado;

  const TelaAtestado({
    super.key,
    required this.student,
    required this.data,
    required this.onAnexado,
  });

  @override
  State<TelaAtestado> createState() => _TelaAtestadoState();
}

class _TelaAtestadoState extends State<TelaAtestado> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _arquivoNome;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    // Pré-carrega o arquivo já salvo, se existir
    _arquivoNome = widget.student.atestadoNome[widget.data];
  }

  // ── Seletor de arquivo (Web) ──────────────────────────────────────────────
  Future<void> _selecionarArquivo() async {
    setState(() => _carregando = true);

    final completer = Completer<String?>();
    final input = html.FileUploadInputElement()
      ..accept = '.pdf,.jpg,.jpeg,.png';

    input.onChange.listen((e) {
      final files = input.files;
      completer.complete(
        (files != null && files.isNotEmpty) ? files.first.name : null,
      );
    });

    input.click();

    final nome = await completer.future;

    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (nome != null) _arquivoNome = nome;
    });
  }

  // ── Confirmar e voltar ────────────────────────────────────────────────────
  void _confirmar() {
    if (_arquivoNome == null) return;
    widget.onAnexado(_arquivoNome!);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Arquivo "$_arquivoNome" salvo!'),
        backgroundColor: const Color(0xFF4CAF50),
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
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comprovante de atestado',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '${widget.student.name} — ${_formatDate(widget.data)}',
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card de preview ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  Icon(
                    _arquivoNome != null
                        ? Icons.check_circle_outline
                        : Icons.upload_file_outlined,
                    size: 48,
                    color: _arquivoNome != null
                        ? const Color(0xFF4CAF50)
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _arquivoNome ?? 'Nenhum arquivo selecionado',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _arquivoNome != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Formatos aceitos: PDF, JPG, PNG',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Botão selecionar arquivo ────────────────────────────────
            OutlinedButton.icon(
              onPressed: _carregando ? null : _selecionarArquivo,
              icon: _carregando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.attach_file, size: 18),
              label: Text(_arquivoNome != null ? 'Trocar arquivo' : 'Selecionar arquivo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFC107),
                side: const BorderSide(color: Color(0xFFFFC107)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // ── Botão confirmar ─────────────────────────────────────────
            FilledButton(
              onPressed: _arquivoNome != null ? _confirmar : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Confirmar', style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
