import 'package:controle_instrumentos/features/instrumentos/ui/instrumentos_page_utils.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/widgets/instrumento_card.dart';
import 'package:flutter/material.dart';

class InstrumentosContent extends StatelessWidget {
  const InstrumentosContent({
    super.key,
    required this.isLoading,
    required this.erroCarregamento,
    required this.instrumentosFiltrados,
    required this.nomesAlunosPorId,
    required this.onRetry,
    required this.onTapItem,
    required this.onEditItem,
    required this.onDeleteItem,
  });

  final bool isLoading;
  final String? erroCarregamento;
  final List<Map<String, dynamic>> instrumentosFiltrados;
  final Map<int, String> nomesAlunosPorId;
  final VoidCallback onRetry;
  final void Function(InstrumentoListItemData item) onTapItem;
  final void Function(Map<String, dynamic> rawItem) onEditItem;
  final void Function(dynamic idInstrumento) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (erroCarregamento != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nao foi possivel carregar os instrumentos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                erroCarregamento!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (instrumentosFiltrados.isEmpty) {
      return const Center(child: Text('Nenhum instrumento encontrado.'));
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        120 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: instrumentosFiltrados.length,
      itemBuilder: (context, index) {
        final item = instrumentosFiltrados[index];
        final data = InstrumentoListItemData.fromMap(
          item,
          nomesAlunosPorId: nomesAlunosPorId,
        );

        return InstrumentoCard(
          nome: data.nome,
          patrimonio: data.patrimonio,
          status: data.status,
          alunoNome: data.alunoNome,
          propriedade: data.propriedade,
          levaInstrumento: data.levaInstrumento,
          observacoes: data.observacoes,
          imageUrl: data.imageUrl,
          onTap: () => onTapItem(data),
          onEdit: () => onEditItem(item),
          onDelete: () => onDeleteItem(data.idInstrumento),
        );
      },
    );
  }
}
