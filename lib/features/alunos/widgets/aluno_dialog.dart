import 'package:controle_instrumentos/features/alunos/widgets/aluno_dialog/aluno_dialog_actions_row.dart';
import 'package:controle_instrumentos/features/alunos/widgets/aluno_dialog/aluno_dialog_fields_section.dart';
import 'package:controle_instrumentos/features/alunos/widgets/aluno_dialog/aluno_dialog_photo_section.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AlunoDialog extends StatefulWidget {
  const AlunoDialog({super.key, this.aluno, required this.onSalvar});

  final Map<String, dynamic>? aluno;
  final Future<void> Function(Map<String, dynamic> dados, XFile? imagemFile)
  onSalvar;

  @override
  State<AlunoDialog> createState() => _AlunoDialogState();
}

class _AlunoDialogState extends State<AlunoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _instrumentoCtrl;
  late final TextEditingController _idadeCtrl;

  String? _setorSelecionado;
  String? _categoriaSelecionada;
  String? _nivelSelecionado;
  bool _salvando = false;

  XFile? _imagemSelecionada;
  final _picker = ImagePicker();

  final _setores = ['Dança', 'Escudo', 'Pavilhão', 'Linha', 'Baliza'];
  final _categorias = [
    'Mentor(a)',
    'Kids',
    'Avançar',
    'Aprendiz',
    'Ex-Aprendiz',
  ];
  final _niveis = ['Iniciante', 'Intermediário', 'Avançado'];

  @override
  void initState() {
    super.initState();
    final a = widget.aluno;
    _numeroCtrl = TextEditingController(
      text: a?['numero_aluno']?.toString() ?? '',
    );
    _nomeCtrl = TextEditingController(
      text: a?['nome_completo']?.toString() ?? '',
    );
    _telefoneCtrl = TextEditingController(
      text: a?['telefone']?.toString() ?? '',
    );
    _instrumentoCtrl = TextEditingController(
      text: a?['id_instrumento']?.toString() ?? '',
    );
    _idadeCtrl = TextEditingController(text: a?['idade']?.toString() ?? '');
    _setorSelecionado = a?['setor']?.toString();
    _categoriaSelecionada = a?['categoria_usuario']?.toString();
    _nivelSelecionado = a?['nivel']?.toString();
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _instrumentoCtrl.dispose();
    _idadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final possuiImagemAtual =
        _imagemSelecionada != null ||
        (widget.aluno?['imagem_url'] != null &&
            (widget.aluno!['imagem_url'] as String).isNotEmpty);

    final origem = await showAlunoImagemOrigemSheet(
      context: context,
      exibirRemover: possuiImagemAtual,
    );

    if (!mounted) return;

    if (origem == null && _imagemSelecionada != null) {
      setState(() => _imagemSelecionada = null);
      return;
    }
    if (origem == null) return;

    final imagem = await _picker.pickImage(
      source: origem,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (imagem != null && mounted) {
      setState(() => _imagemSelecionada = imagem);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final dados = {
        'numero_aluno': int.tryParse(_numeroCtrl.text.trim()),
        'nome_completo': _nomeCtrl.text.trim(),
        'setor': _setorSelecionado,
        'categoria_usuario': _categoriaSelecionada,
        'nivel': _nivelSelecionado,
        if (_telefoneCtrl.text.trim().isNotEmpty)
          'telefone': _telefoneCtrl.text.trim(),
        if (_instrumentoCtrl.text.trim().isNotEmpty)
          'id_instrumento': int.tryParse(_instrumentoCtrl.text.trim()),
        if (_idadeCtrl.text.trim().isNotEmpty)
          'idade': int.tryParse(_idadeCtrl.text.trim()),
      };
      await widget.onSalvar(dados, _imagemSelecionada);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String? _validarNumero(String? v) {
    if (v == null || v.isEmpty) return 'Informe o número';
    if (int.tryParse(v) == null) return 'Digite apenas números';
    return null;
  }

  String? _validarNome(String? v) {
    if (v == null || v.isEmpty) return 'Informe o nome';
    return null;
  }

  String? _validarIdade(String? v) {
    if (v == null || v.isEmpty) return null;
    final parsed = int.tryParse(v);
    if (parsed == null) return 'Digite apenas números';
    if (parsed < 1 || parsed > 120) return 'Idade inválida';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.aluno != null;
    final imagemUrlExistente = widget.aluno?['imagem_url'] as String?;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isEdicao ? 'Editar Aluno' : 'Adicionar Novo Aluno',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AlunoDialogFotoSection(
                imagemSelecionada: _imagemSelecionada,
                imagemUrlExistente: imagemUrlExistente,
                onTap: _selecionarImagem,
              ),
              AlunoDialogFieldsSection(
                numeroCtrl: _numeroCtrl,
                nomeCtrl: _nomeCtrl,
                idadeCtrl: _idadeCtrl,
                telefoneCtrl: _telefoneCtrl,
                setorSelecionado: _setorSelecionado,
                categoriaSelecionada: _categoriaSelecionada,
                nivelSelecionado: _nivelSelecionado,
                setores: _setores,
                categorias: _categorias,
                niveis: _niveis,
                onSetorChanged: (v) => setState(() => _setorSelecionado = v),
                onCategoriaChanged: (v) =>
                    setState(() => _categoriaSelecionada = v),
                onNivelChanged: (v) => setState(() => _nivelSelecionado = v),
                numeroValidator: _validarNumero,
                nomeValidator: _validarNome,
                idadeValidator: _validarIdade,
              ),
              const SizedBox(height: 20),
              AlunoDialogActionsRow(
                salvando: _salvando,
                isEdicao: isEdicao,
                onCancel: () => Navigator.pop(context),
                onSave: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
