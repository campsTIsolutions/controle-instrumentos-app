import 'package:flutter/material.dart';

class AlunoDialogFieldsSection extends StatelessWidget {
  const AlunoDialogFieldsSection({
    super.key,
    required this.numeroCtrl,
    required this.nomeCtrl,
    required this.idadeCtrl,
    required this.telefoneCtrl,
    required this.setorSelecionado,
    required this.categoriaSelecionada,
    required this.nivelSelecionado,
    required this.setores,
    required this.categorias,
    required this.niveis,
    required this.onSetorChanged,
    required this.onCategoriaChanged,
    required this.onNivelChanged,
    required this.numeroValidator,
    required this.nomeValidator,
    required this.idadeValidator,
  });

  final TextEditingController numeroCtrl;
  final TextEditingController nomeCtrl;
  final TextEditingController idadeCtrl;
  final TextEditingController telefoneCtrl;

  final String? setorSelecionado;
  final String? categoriaSelecionada;
  final String? nivelSelecionado;

  final List<String> setores;
  final List<String> categorias;
  final List<String> niveis;

  final ValueChanged<String?> onSetorChanged;
  final ValueChanged<String?> onCategoriaChanged;
  final ValueChanged<String?> onNivelChanged;

  final String? Function(String?) numeroValidator;
  final String? Function(String?) nomeValidator;
  final String? Function(String?) idadeValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AlunoCampoTexto(
          label: 'Número do Aluno',
          controller: numeroCtrl,
          keyboardType: TextInputType.number,
          validator: numeroValidator,
        ),
        const SizedBox(height: 12),
        AlunoCampoTexto(
          label: 'Nome Completo',
          controller: nomeCtrl,
          validator: nomeValidator,
        ),
        const SizedBox(height: 12),
        AlunoCampoTexto(
          label: 'Idade',
          hint: 'Ex: 17',
          controller: idadeCtrl,
          keyboardType: TextInputType.number,
          validator: idadeValidator,
        ),
        const SizedBox(height: 12),
        AlunoCampoDropdown(
          label: 'Setor',
          hint: 'Selecionar Setor',
          valor: setorSelecionado,
          opcoes: setores,
          onChanged: onSetorChanged,
          validator: (v) => v == null ? 'Selecione um setor' : null,
        ),
        const SizedBox(height: 12),
        AlunoCampoDropdown(
          label: 'Categoria do Usuário',
          hint: 'Selecionar Categoria',
          valor: categoriaSelecionada,
          opcoes: categorias,
          onChanged: onCategoriaChanged,
          validator: (v) => v == null ? 'Selecione uma categoria' : null,
        ),
        const SizedBox(height: 12),
        AlunoCampoDropdown(
          label: 'Nível de Conhecimento',
          hint: 'Selecionar Nível',
          valor: nivelSelecionado,
          opcoes: niveis,
          onChanged: onNivelChanged,
          validator: (v) => v == null ? 'Selecione um nível' : null,
        ),
        const SizedBox(height: 12),
        AlunoCampoTexto(
          label: 'Telefone (Opcional)',
          hint: '(99) 99999-9999',
          controller: telefoneCtrl,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}

class AlunoCampoTexto extends StatelessWidget {
  const AlunoCampoTexto({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black38),
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
        ),
      ],
    );
  }
}

class AlunoCampoDropdown extends StatelessWidget {
  const AlunoCampoDropdown({
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
  final void Function(String?) onChanged;
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
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, style: const TextStyle(color: Colors.black87)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
