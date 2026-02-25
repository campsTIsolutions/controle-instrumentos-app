import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('SUPABASE_URL (env): "${SupabaseConfig.url}"');
  print('SUPABASE_ANON_KEY (env): "${SupabaseConfig.anonKey}"');

  print("URL atual: ${SupabaseConfig.url}");

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}
