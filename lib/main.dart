import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ylcfdbonhrvvbclinado.supabase.co',
    anonKey: 'sb_publishable_YopOGM9CpLfvJXXiKNTHJw_Tx1RtZDn.anonKey',
  );

  runApp(const MyApp());
}
