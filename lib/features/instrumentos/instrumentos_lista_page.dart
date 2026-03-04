import 'package:flutter/material.dart';
import 'models/instrumentos_model.dart';
import 'repository/instrumentos_repository.dart';

class InstrumentosListaPage extends StatefulWidget {
  const InstrumentosListaPage({super.key});

  @override
  State<InstrumentosListaPage> createState() => _InstrumentosListaPageState();
}

class _InstrumentosListaPageState extends State<InstrumentosListaPage> {
  final InstrumentosRepository _repository = InstrumentosRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Instrumentos')),
      body: FutureBuilder<List<Instrumentos>>(
        future: _repository.listarTodos(), // Chama a função do Repositório
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final lista = snapshot.data ?? [];

          return ListView.builder(
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final item = lista[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(item.foto_url),
                ),
                title: Text(item.nome_instrumento),
                subtitle: Text('Património: ${item.numero_patrimonio}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Color.fromARGB(255, 54, 174, 244)),
                  onPressed: () async {
                    // Exemplo de DELETE
                    await _repository.eliminar(item.id_instrumento!);
                    setState(() {}); // Recarrega a lista
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Ir para o para o formulário de criação
        },
      ),
    );
  }
}