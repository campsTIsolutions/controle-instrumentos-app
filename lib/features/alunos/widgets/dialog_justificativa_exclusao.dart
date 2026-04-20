import 'package:flutter/material.dart';

class DialogJustificativaExclusao extends StatefulWidget {
  const DialogJustificativaExclusao({super.key});

  @override
  State<DialogJustificativaExclusao> createState() =>
      _DialogJustificativaExclusaoState();
}

class _DialogJustificativaExclusaoState
    extends State<DialogJustificativaExclusao> {
  String? _motivoSelecionado;
  final _outroCtrl = TextEditingController();
  bool _confirmando = false;

  static const _motivos = [
    'Falta de Tempo',
    'Falta de Disciplina',
    'Falta de Interesse',
    'Outro',
  ];

  static const _icones = {
    'Falta de Tempo': Icons.schedule_outlined,
    'Falta de Disciplina': Icons.rule_outlined,
    'Falta de Interesse': Icons.sentiment_dissatisfied_outlined,
    'Outro': Icons.edit_note_outlined,
  };

  @override
  void dispose() {
    _outroCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (_motivoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um motivo para a exclusão.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_motivoSelecionado == 'Outro' && _outroCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Descreva o motivo da exclusão.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final motivo = _motivoSelecionado == 'Outro'
        ? 'Outro: ${_outroCtrl.text.trim()}'
        : _motivoSelecionado!;

    Navigator.pop(context, {'motivo': motivo});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB91C1C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Excluir Aluno',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Esta ação não pode ser desfeita.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Motivo da exclusão',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selecione o principal motivo pelo qual este aluno está sendo desligado.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 14),
            ...(_motivos.map((motivo) {
              final selecionado = _motivoSelecionado == motivo;
              return GestureDetector(
                onTap: () => setState(() => _motivoSelecionado = motivo),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? const Color(0xFFB91C1C).withOpacity(0.15)
                        : const Color(0xFF2A2A3E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selecionado
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF374151),
                      width: selecionado ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _icones[motivo]!,
                        size: 20,
                        color: selecionado
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          motivo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selecionado
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: selecionado
                                ? Colors.white
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                      if (selecionado)
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                    ],
                  ),
                ),
              );
            })),
            if (_motivoSelecionado == 'Outro') ...[
              const SizedBox(height: 4),
              TextFormField(
                controller: _outroCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Descreva o motivo da exclusão...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2A2A3E),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF374151)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF374151)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _confirmando
                        ? null
                        : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmando ? null : _confirmar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _confirmando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Confirmar Exclusão',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
