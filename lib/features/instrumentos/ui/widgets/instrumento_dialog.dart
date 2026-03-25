import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _patrimonioCtrl;
  late final TextEditingController _observacoesCtrl;
  late final TextEditingController _propriedadeCtrl;
  late final TextEditingController _imagemUrlCtrl;

  bool _levaInstrumento = false;
  bool _disponivel = true;
  bool _salvando = false;

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
    _propriedadeCtrl = TextEditingController(
    text: i?['propriedade_instrumento']?.toString() ?? '',
    );

    _imagemUrlCtrl = TextEditingController(
      text: i?['imagem_url']?.toString() ?? '',
    );

    _levaInstrumento = i?['leva_instrumento'] == true;
  }

  @override
  void dispose() {
    _propriedadeCtrl.dispose();
    _imagemUrlCtrl.dispose();
    _nomeCtrl.dispose();
    _patrimonioCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _salvando = true);

  try {
    final dados = <String, dynamic>{
      'numero_patrimonio': _patrimonioCtrl.text.trim(),
      'nome_instrumento': _nomeCtrl.text.trim(),
      'disponivel': _disponivel,
      'propriedade_instrumento': _propriedadeCtrl.text.trim().isEmpty
          ? null
          : _propriedadeCtrl.text.trim(),
      'leva_instrumento': _levaInstrumento,
      'observacoes': _observacoesCtrl.text.trim().isEmpty
          ? null
          : _observacoesCtrl.text.trim(),
      'imagem_url': _imagemUrlCtrl.text.trim().isEmpty
          ? null
          : _imagemUrlCtrl.text.trim(),
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
                activeColor: const Color(0xFF2563EB),
              ),
              InstrumentoText(
                label: 'Propriedade do Instrumento',
                controller: _propriedadeCtrl,
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

              InstrumentoText(
                label: 'Imagem URL',
                controller: _imagemUrlCtrl,
              ),
              const SizedBox(height: 12),
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