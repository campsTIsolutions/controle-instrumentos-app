import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    );

    if (resultado == null) return;

    final arquivo = resultado.files.single;
    setState(() {
      _imagemPath = arquivo.path;
      _imagemNome = arquivo.name;
    });
  }

  Future<void> _carregarAlunos() async {
    try {
      final response = await _supabase
          .from('alunos')
          .select('id_aluno, nome_completo')
          .order('nome_completo', ascending: true);

      if (!mounted) return;

      final alunos = List<Map<String, dynamic>>.from(
        (response as List).map((item) => Map<String, dynamic>.from(item)),
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
      final dados = <String, dynamic>{
        'numero_patrimonio': _patrimonioCtrl.text.trim(),
        'nome_instrumento': _nomeCtrl.text.trim(),
        'propriedade_instrumento': _propriedadeSelecionada,
        'id_aluno': _alunoSelecionadoId,
        'leva_instrumento': _levaInstrumento,
        'observacoes': _observacoesCtrl.text.trim().isEmpty
            ? null
            : _observacoesCtrl.text.trim(),
        'imagem_url': (_imagemPath == null || _imagemPath!.trim().isEmpty)
            ? null
            : _imagemPath!.trim(),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                label: 'Numero do Patrimonio',
                controller: _patrimonioCtrl,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Informe o patrimonio'
                    : null,
              ),
              const SizedBox(height: 12),
              InstrumentoText(
                label: 'Observacoes',
                controller: _observacoesCtrl,
              ),
              const SizedBox(height: 12),
              _CampoDropdown(
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
              _CampoAlunoDropdown(
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
                activeColor: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Imagem do Instrumento',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _imagemNome ?? 'Nenhum arquivo selecionado',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    if (_imagemPath != null && _imagemPath!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _imagemPath!,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _salvando ? null : _selecionarArquivo,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Escolher arquivo'),
                        ),
                        if (_imagemPath != null && _imagemPath!.isNotEmpty)
                          OutlinedButton(
                            onPressed: _salvando
                                ? null
                                : () {
                                    setState(() {
                                      _imagemPath = null;
                                      _imagemNome = null;
                                    });
                                  },
                            child: const Text('Remover'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Disponivel',
                  style: TextStyle(color: Colors.white),
                ),
                value: _disponivel,
                onChanged: _salvando
                    ? null
                    : (value) {
                        setState(() => _disponivel = value);
                      },
                activeColor: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _salvando ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              isEdicao ? 'Salvar' : 'Adicionar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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

class _CampoDropdown extends StatelessWidget {
  const _CampoDropdown({
    required this.label,
    required this.hint,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
    this.validator,
  });

  final String label;
  final String hint;
  final String? valor;
  final List<String> opcoes;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: valor,
          hint: Text(hint, style: const TextStyle(color: Colors.black38)),
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
          ),
          items: opcoes
              .map(
                (opcao) => DropdownMenuItem<String>(
                  value: opcao,
                  child: Text(
                    opcao,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CampoAlunoDropdown extends StatelessWidget {
  const _CampoAlunoDropdown({
    required this.label,
    required this.valor,
    required this.carregando,
    required this.opcoes,
    required this.onChanged,
  });

  final String label;
  final int? valor;
  final bool carregando;
  final List<Map<String, dynamic>> opcoes;
  final void Function(int?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int?>(
          initialValue: valor,
          onChanged: carregando ? null : onChanged,
          hint: Text(
            carregando ? 'Carregando alunos...' : 'Selecionar aluno',
            style: const TextStyle(color: Colors.black38),
          ),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'Sem aluno vinculado',
                style: TextStyle(color: Colors.black87),
              ),
            ),
            ...opcoes.map(
              (aluno) => DropdownMenuItem<int?>(
                value: aluno['id_aluno'] as int,
                child: Text(
                  aluno['nome_completo']?.toString() ?? '',
                  style: const TextStyle(color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
