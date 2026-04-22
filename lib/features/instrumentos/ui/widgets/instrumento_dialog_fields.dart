import 'package:flutter/material.dart';

class InstrumentoCampoDropdown extends StatelessWidget {
  const InstrumentoCampoDropdown({
    super.key,
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

class InstrumentoCampoAlunoDropdown extends StatelessWidget {
  const InstrumentoCampoAlunoDropdown({
    super.key,
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

class InstrumentoImagemField extends StatelessWidget {
  const InstrumentoImagemField({
    super.key,
    required this.imagemNome,
    required this.imagemPath,
    required this.salvando,
    required this.onSelecionarArquivo,
    required this.onRemoverArquivo,
  });

  final String? imagemNome;
  final String? imagemPath;
  final bool salvando;
  final VoidCallback onSelecionarArquivo;
  final VoidCallback onRemoverArquivo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                imagemNome ?? 'Nenhum arquivo selecionado',
                style: const TextStyle(color: Colors.black87),
              ),
              if (imagemPath != null && imagemPath!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  imagemPath!,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: salvando ? null : onSelecionarArquivo,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Escolher arquivo'),
                  ),
                  if (imagemPath != null && imagemPath!.isNotEmpty)
                    OutlinedButton(
                      onPressed: salvando ? null : onRemoverArquivo,
                      child: const Text('Remover'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InstrumentoDialogActionsRow extends StatelessWidget {
  const InstrumentoDialogActionsRow({
    super.key,
    required this.salvando,
    required this.isEdicao,
    required this.onCancelar,
    required this.onSalvar,
  });

  final bool salvando;
  final bool isEdicao;
  final VoidCallback onCancelar;
  final VoidCallback onSalvar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: salvando ? null : onCancelar,
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
            onPressed: salvando ? null : onSalvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: salvando
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
    );
  }
}
