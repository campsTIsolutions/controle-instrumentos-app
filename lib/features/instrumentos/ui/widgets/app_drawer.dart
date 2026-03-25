import 'package:flutter/material.dart';
import 'package:controle_instrumentos/features/alunos/alunos_page.dart';
import 'package:controle_instrumentos/features/instrumentos/ui/instrumentos_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 200,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Menu',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            const Divider(height: 1, thickness: 2),

            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Instrumentos'),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const InstrumentosPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Chamada'),
              onTap: null,
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Alunos'),
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const AlunosPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
