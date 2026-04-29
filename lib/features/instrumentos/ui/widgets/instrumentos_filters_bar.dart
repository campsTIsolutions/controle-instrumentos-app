import 'package:flutter/material.dart';

class InstrumentosFiltersBar extends StatelessWidget {
  const InstrumentosFiltersBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.ordenarAlfabetico,
    required this.onOrdenarAlfabeticoChanged,
    required this.filtroPropriedade,
    required this.propriedades,
    required this.onFiltroPropriedadeChanged,
    required this.filtroStatus,
    required this.statusDisponibilidade,
    required this.onFiltroStatusChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool ordenarAlfabetico;
  final ValueChanged<bool> onOrdenarAlfabeticoChanged;
  final String? filtroPropriedade;
  final List<String> propriedades;
  final ValueChanged<String?> onFiltroPropriedadeChanged;
  final String? filtroStatus;
  final List<String> statusDisponibilidade;
  final ValueChanged<String?> onFiltroStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Pesquisar instrumento...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color.fromARGB(255, 255, 255, 255),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onOrdenarAlfabeticoChanged(!ordenarAlfabetico),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: ordenarAlfabetico
                          ? const Color(0xFFEFF6FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ordenarAlfabetico
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'A-Z',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ordenarAlfabetico
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: InstrumentosFiltroDropdown(
                  hint: 'Prop.',
                  valor: filtroPropriedade,
                  opcoes: propriedades,
                  onChanged: onFiltroPropriedadeChanged,
                  onLimpar: () => onFiltroPropriedadeChanged(null),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: InstrumentosFiltroDropdown(
                  hint: 'Status',
                  valor: filtroStatus,
                  opcoes: statusDisponibilidade,
                  onChanged: onFiltroStatusChanged,
                  onLimpar: () => onFiltroStatusChanged(null),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class InstrumentosFiltroDropdown extends StatelessWidget {
  const InstrumentosFiltroDropdown({
    super.key,
    required this.hint,
    required this.valor,
    required this.opcoes,
    required this.onChanged,
    required this.onLimpar,
  });

  final String hint;
  final String? valor;
  final List<String> opcoes;
  final ValueChanged<String?> onChanged;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isExpanded: true,
          isDense: true,
          iconSize: 18,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            overflow: TextOverflow.ellipsis,
          ),
          borderRadius: BorderRadius.circular(10),
          items: [
            ...opcoes.map(
              (opcao) => DropdownMenuItem<String>(
                value: opcao,
                child: Text(
                  opcao,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            if (valor != null)
              const DropdownMenuItem<String>(
                value: '__limpar__',
                child: Text(
                  'Limpar',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
          onChanged: (value) {
            if (value == '__limpar__') {
              onLimpar();
              return;
            }
            onChanged(value);
          },
        ),
      ),
    );
  }
}
