import 'package:flutter/material.dart';
import 'instrumento_text.dart';

class InstrumentoDialog extends StatefulWidget {
  const InstrumentoDialog({
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
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _alunoCtrl;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final i = widget.instrumento;

    _nomeCtrl = TextEditingController(
      text: i?['nome']?.toString() ?? '',
    );
    _tipoCtrl = TextEditingController(
      text: i?['tipo']?.toString() ?? '',
    );
    _alunoCtrl = TextEditingController(
      text: i?['aluno']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _tipoCtrl.dispose();
    _alunoCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final dados = {
        'nome': _nomeCtrl.text.trim(),
        'tipo': _tipoCtrl.text.trim(),
        'aluno': _alunoCtrl.text.trim(),
      };

      await widget.onSalvar(dados);
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              InstrumentoText(
                label: 'Nome do Instrumento',
                controller: _nomeCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),

              InstrumentoText(
                label: 'Tipo',
                controller: _tipoCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o tipo' : null,
              ),
              const SizedBox(height: 12),

              InstrumentoText(
                label: 'Aluno',
                controller: _alunoCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o aluno' : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _salvando
                          ? null
                          : () => Navigator.pop(context),
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