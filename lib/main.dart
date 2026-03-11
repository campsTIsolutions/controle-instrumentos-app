import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // registro global de erros para capturar problemas que parariam a UI
  FlutterError.onError = (details) {
    // ignore: avoid_print
    print('FlutterError.onError: ${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    // ignore: avoid_print
    print('PlatformDispatcher.onError: $error\n$stack');
    return true;
  };
  print('SUPABASE_URL (env): "${SupabaseConfig.url}"');
  print('SUPABASE_ANON_KEY (env): "${SupabaseConfig.anonKey}"');

  print("URL atual: ${SupabaseConfig.url}");

  await Supabase.initialize(
    url: 'https://ylcfdbonhrvvbclinado.supabase.co',
    anonKey: 'sb_publishable_YopOGM9CpLfvJXXiKNTHJw_Tx1RtZDn.anonKey',
  );

  runApp(const MyApp());
}
