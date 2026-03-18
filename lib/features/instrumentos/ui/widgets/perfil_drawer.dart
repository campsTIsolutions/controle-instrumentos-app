import 'package:flutter/material.dart';
import '../../../login/login_page.dart';

class PerfilDrawer extends StatelessWidget {
  const PerfilDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 200, 
      child: SafeArea(
        child: Column(  
          children: [
            const SizedBox(height: 20),
            const Text(
              'Perfil',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),

            const Divider(
              height: 1,
              thickness: 2,
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Meu Perfil'),
              onTap: () {
                Navigator.pop(context);
              },
            ),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}