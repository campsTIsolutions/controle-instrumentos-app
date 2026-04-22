import 'dart:typed_data';

import 'package:controle_instrumentos/core/config/storage_paths.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'instrumento_dialog_fields.dart';
import 'instrumento_text.dart';

class InstrumentoDialog extends StatefulWidget {
  const InstrumentoDialog({
    super.key,
    this.instrumento,
    required this.onSalvar,
  });

  final Map<String, dynamic>? instrumento;
  final Future<void> Function(Map<String, dynamic>) onSalvar;

  @override
  State<InstrumentoDialog> createState() => _InstrumentoDialogState();
}

class _InstrumentoDialogState extends State<InstrumentoDialog> {
  static const _propriedades = ['CAMPS', 'Terceiros'];
  final _supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _patrimonioCtrl;
  late final TextEditingController _observacoesCtrl;

  bool _levaInstrumento = false;
  bool _disponivel = true;
  bool _salvando = false;
  bool _carregandoAlunos = true;
  String? _propriedadeSelecionada;
  String? _imagemPath;
  String? _imagemNome;
  Uint8List? _imagemBytes;
  int? _alunoSelecionadoId;
  List<Map<String, dynamic>> _alunos = [];

  @override
  void initState() {
    super.initState();
    final i = widget.instrumento;

    _nomeCtrl = TextEditingController(
      text: i?['nome_instrumento']?.toString() ?? '',
    );
    _patrimonioCtrl = TextEditingController(
      text: i?['numero_patrimonio']?.toString() ?? '',
    );
    _observacoesCtrl = TextEditingController(
      text: i?['observacoes']?.toString() ?? '',
    );

    _disponivel = i?['disponivel'] == null ? true : i!['disponivel'] == true;
    _levaInstrumento = i?['leva_instrumento'] == true;

    final propriedadeInicial = i?['propriedade_instrumento']?.toString();
    if (_propriedades.contains(propriedadeInicial)) {
      _propriedadeSelecionada = propriedadeInicial;
    }

    final alunoId = i?['id_aluno'];
    if (alunoId is int) {
      _alunoSelecionadoId = alunoId;
    } else if (alunoId != null) {
      _alunoSelecionadoId = int.tryParse(alunoId.toString());
    }

    _imagemPath = i?['imagem_url']?.toString();
    if (_imagemPath != null && _imagemPath!.isNotEmpty) {
      _imagemNome = _imagemPath!.split(RegExp(r'[\\/]')).last;
    }

    _carregarAlunos();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _patrimonioCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarArquivo() async {
    if (_salvando) return;

    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (resultado == null) return;

    final arquivo = resultado.files.single;
    setState(() {
      _imagemPath = arquivo.path;
      _imagemNome = arquivo.name;
      _imagemBytes = arquivo.bytes;
    });
  }

  Future<void> _carregarAlunos() async {
    try {
      final response = await _supabase
          .from('alunos')
          .select('id_aluno, nome_completo')
          .order('nome_completo', ascending: true);

      if (!mounted) return;

      final dynamic rawResponse = response;
      final rawData = rawResponse is PostgrestResponse
          ? rawResponse.data
          : rawResponse;
      final alunos = List<Map<String, dynamic>>.from(
        (rawData as List).map((item) => Map<String, dynamic>.from(item as Map)),
      );

      setState(() {
        _alunos = alunos;
        _carregandoAlunos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoAlunos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar alunos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      var imagemUrl = _imagemPath;

      if (_imagemBytes != null && _imagemNome != null) {
        final safeFileName = _imagemNome!
            .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
            .replaceAll(' ', '_');
        final objectPath = StoragePaths.instrumentoObjectPath(
          safeFileName,
          DateTime.now().millisecondsSinceEpoch,
        );

        await _supabase.storage
            .from(StoragePaths.bucket)
            .uploadBinary(objectPath, _imagemBytes!);

        imagemUrl = _supabase.storage
            .from(StoragePaths.bucket)
            .getPublicUrl(objectPath);
      }

      final dados = <String, dynamic>{
        'numero_patrimonio': _patrimonioCtrl.text.trim(),
        'nome_instrumento': _nomeCtrl.text.trim(),
        'propriedade_instrumento': _propriedadeSelecionada,
        'id_aluno': _alunoSelecionadoId,
        'leva_instrumento': _levaInstrumento,
        'observacoes': _observacoesCtrl.text.trim().isEmpty
            ? null
            : _observacoesCtrl.text.trim(),
        'imagem_url': (imagemUrl == null || imagemUrl.trim().isEmpty)
            ? null
            : imagemUrl.trim(),
        'disponivel': _disponivel,
      };

      await widget.onSalvar(dados);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.instrumento != null;

    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdicao ? 'Editar Instrumento' : 'Adicionar Instrumento',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _salvando ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InstrumentoText(
                label: 'Nome do Instrumento',
                controller: _nomeCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              InstrumentoText(
                label: 'Número do Patrimônio',
                controller: _patrimonioCtrl,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Informe o patrimônio'
                    : null,
              ),
              const SizedBox(height: 12),
              InstrumentoText(
                label: 'Observações',
                controller: _observacoesCtrl,
              ),
              const SizedBox(height: 12),
              InstrumentoCampoDropdown(
                label: 'Propriedade do Instrumento',
                hint: 'Selecionar propriedade',
                valor: _propriedadeSelecionada,
                opcoes: _propriedades,
                validator: (value) =>
                    value == null ? 'Selecione a propriedade' : null,
                onChanged: _salvando
                    ? null
                    : (value) {
                        setState(() => _propriedadeSelecionada = value);
                      },
              ),
              const SizedBox(height: 12),
              InstrumentoCampoAlunoDropdown(
                label: 'Aluno Vinculado',
                valor: _alunoSelecionadoId,
                carregando: _carregandoAlunos,
                opcoes: _alunos,
                onChanged: _salvando
                    ? null
                    : (value) {
                        setState(() => _alunoSelecionadoId = value);
                      },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Leva Instrumento',
                  style: TextStyle(color: Colors.white),
                ),
                value: _levaInstrumento,
                onChanged: _salvando
                    ? null
                    : (value) {
                        setState(() => _levaInstrumento = value);
                      },
                activeThumbColor: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              InstrumentoImagemField(
                imagemNome: _imagemNome,
                imagemPath: _imagemPath,
                salvando: _salvando,
                onSelecionarArquivo: _selecionarArquivo,
                onRemoverArquivo: () {
                  setState(() {
                    _imagemPath = null;
                    _imagemNome = null;
                    _imagemBytes = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Disponível',
                  style: TextStyle(color: Colors.white),
                ),
                value: _disponivel,
                onChanged: _salvando
                    ? null
                    : (value) {
                        setState(() => _disponivel = value);
                      },
                activeThumbColor: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 20),
              InstrumentoDialogActionsRow(
                salvando: _salvando,
                isEdicao: isEdicao,
                onCancelar: () => Navigator.pop(context),
                onSalvar: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
