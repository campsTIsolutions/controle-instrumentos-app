import 'package:flutter/material.dart';
import '../data/instruments_repository.dart';
import 'widgets/instrumento_card.dart';
class InstrumentosPage extends StatefulWidget {
  const InstrumentosPage({super.key});

  @override
  State<InstrumentosPage> createState() => _InstrumentosPageState();
}

class _InstrumentosPageState extends State<InstrumentosPage> {
  final repo = InstrumentsRepository();
  late final Future<List<Map<String, dynamic>>> futureInstrumentos;

  @override
  void initState() {
    super.initState();
    futureInstrumentos = repo.fetchInstrumentos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset("assets/menu-icon.png"),
          ),
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: const Color.fromARGB(0, 255, 255, 255),
          ),
        ),
        title: const Text(
          "CAMPS",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey),
        ),
        actions: [
          IconButton(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset("assets/profile.png"),
            ),
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: const Color.fromARGB(0, 255, 255, 255),
            ),
          ),
        ],
      ),

      body: Column(
        children: [

          const SizedBox(height: 15),

          const Text(
            "Controle de Instrumentos",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Pesquisar instrumento...",
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

          const SizedBox(height: 15),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: futureInstrumentos,
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                // MOSTRA UI MESMO COM ERRO (pra você continuar o front)
                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: const [
                    InstrumentoCard(
                      nome: "Violão Tagima",
                      tipo: "Cordas",
                      aluno: "Murilo",
                    ),
                    InstrumentoCard(
                      nome: "Bateria Pearl",
                      tipo: "Percussão",
                      aluno: "Carlos",
                    ),
                  ],
                );
              }

                final instrumentos = snapshot.data ?? [];

                if (instrumentos.isEmpty) {
                  return const Center(
                    child: Text("Nenhum instrumento cadastrado."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: instrumentos.length,
                  itemBuilder: (context, index) {

                    final item = instrumentos[index];

                    final nome = (item['nome'] ?? '').toString();
                    final tipo = (item['tipo'] ?? '').toString();
                    final aluno = (item['aluno'] ?? '').toString();

                    return InstrumentoCard(
                      nome: nome,
                      tipo: tipo,
                      aluno: aluno,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}