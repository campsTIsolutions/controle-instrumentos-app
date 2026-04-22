// lib/features/chamada/tela_atestado.dart
// Tela dedicada ao comprovante de atestado médico.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/widgets/app_drawer.dart';
import 'package:controle_instrumentos/features/chamada/atestado_utils.dart';
import 'package:controle_instrumentos/shared/widgets/profile_menu_button.dart';
import 'models.dart';
import 'supabase_service.dart';

class TelaAtestado extends StatefulWidget {
  final StudentRecord student;
  final DateTime data;

  /// Callback chamado ao confirmar o arquivo — passa a URL salva.
  final Future<void> Function(String comprovanteUrl) onAnexado;

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
  String? _comprovanteUrl;
  String? _arquivoNome;
  Uint8List? _arquivoBytes;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    // Pré-carrega o arquivo já salvo, se existir
    _comprovanteUrl = widget.student.atestadoNome[widget.data];
    if (_comprovanteUrl != null) {
      _arquivoNome = extrairNomeArquivoAtestado(_comprovanteUrl);
    }
  }

  // ── Seletor de arquivo (Android/Web/Desktop) ─────────────────────────────
  Future<void> _selecionarArquivo() async {
    setState(() => _carregando = true);

    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final arquivo = resultado?.files.single;
    final nome = arquivo?.name;
    final bytes = arquivo?.bytes;

    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (nome != null) {
        _arquivoNome = nome;
        _arquivoBytes = bytes;
      }
    });
  }

  // ── Confirmar e voltar ────────────────────────────────────────────────────
  Future<void> _confirmar() async {
    if (_arquivoNome == null) return;

    setState(() => _carregando = true);
    try {
      var urlFinal = _comprovanteUrl;
      if (_arquivoBytes != null) {
        urlFinal = await SupabaseService.uploadComprovanteAtestado(
          idAluno: widget.student.idAluno,
          data: widget.data,
          bytes: _arquivoBytes!,
          originalFileName: _arquivoNome!,
        );
      }

      if (urlFinal == null || urlFinal.isEmpty) return;

      await widget.onAnexado(urlFinal);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arquivo "$_arquivoNome" salvo!'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar atestado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
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
          const ProfileMenuButton(),
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
                    color: Colors.black.withValues(alpha: 0.05),
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
              label: Text(
                _arquivoNome != null ? 'Trocar arquivo' : 'Selecionar arquivo',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFC107),
                side: const BorderSide(color: Color(0xFFFFC107)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 12),

            // ── Botão confirmar ─────────────────────────────────────────
            FilledButton(
              onPressed: (_arquivoNome != null && !_carregando)
                  ? _confirmar
                  : null,
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
