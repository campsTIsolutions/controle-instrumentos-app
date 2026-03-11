import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'app.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
    );
  }
}
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ylcfdbonhrvvbclinado.supabase.co',
    anonKey: 'sb_publishable_YopOGM9CpLfvJXXiKNTHJw_Tx1RtZDn.anonKey',
  );
  
  runApp(const MyApp());
}
