

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:controle_instrumentos/features/login/login_page.dart';
import '../data/instruments_repository.dart';
import 'widgets/instrumento_card.dart';
import 'widgets/app_drawer.dart';
import 'widgets/perfil_drawer.dart';

class InstrumentosPage extends StatefulWidget {
  const InstrumentosPage({super.key});

  @override
  State<InstrumentosPage> createState() => _InstrumentosPageState();
}

class _InstrumentosPageState extends State<InstrumentosPage> {
  final repo = InstrumentsRepository();
  late final Future<List<Map<String, dynamic>>> futureInstrumentos;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    futureInstrumentos = repo.fetchInstrumentos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      endDrawer: const PerfilDrawer(),

      appBar: AppBar(
        leading: IconButton(
          icon: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset("assets/menu-icon.png"),
          ),
          onPressed: () {
            debugPrint("BOTÃO MENU PRESSIONADO");
            _scaffoldKey.currentState?.openDrawer();
          },
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
          Builder(
            builder: (context) => IconButton(
              icon: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset("assets/profile.png"),
              ),
              onPressed: () async {
                final RenderBox button = context.findRenderObject() as RenderBox;
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;

                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    button.localToGlobal(
                      Offset(-15, button.size.height - 8), // desce mais 12 px
                      ancestor: overlay,
                    ),
                    button.localToGlobal(
                      button.size.bottomRight(Offset.zero) + const Offset(-15, -8),
                      ancestor: overlay,
                    ),
                  ),
                  Offset.zero & overlay.size,
                );

                final result = await showMenu<String>(
                  context: context,
                  position: position,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                  color: Colors.white,
                  items: [
                    const PopupMenuItem<String>(
                      value: 'perfil',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline),
                          SizedBox(width: 10),
                          Text('Perfil'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'config',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined),
                          SizedBox(width: 10),
                          Text('Configurações'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'sair',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 10),
                          Text('Sair'),
                        ],
                      ),
                    ),
                  ],
                );

                if (result == 'perfil') {
                  debugPrint('Ir para perfil');
                } else if (result == 'config') {
                  debugPrint('Ir para configurações');
                } else if (result == 'sair') {
                  await Supabase.instance.client.auth.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
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
