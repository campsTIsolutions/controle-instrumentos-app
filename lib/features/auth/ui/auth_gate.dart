import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import '../../home/ui/home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // enquanto carrega
        // debug prints para identificar qual widget está sendo construído
        // ignore: avoid_print
        print(
          'AuthGate: snapshot.hasData=${snapshot.hasData}, snapshot.data=${snapshot.data}',
        );

        if (!snapshot.hasData) {
          // ignore: avoid_print
          print('AuthGate: mostrando CircularProgressIndicator');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data!.session;

        // ignore: avoid_print
        print('AuthGate: session=$session');

        if (session == null) {
          // ignore: avoid_print
          print('AuthGate: mostrando LoginPage');
          return const LoginPage();
        }

        // ignore: avoid_print
        print('AuthGate: mostrando HomePage');
        return const HomePage();
      },
    );
  }
}
