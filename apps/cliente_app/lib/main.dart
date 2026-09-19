import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await initializeDateFormatting('en', null);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // El cierre de sesión forzado aquí fue eliminado para mantener la sesión.
  
  runApp(const ProviderScope(child: MyApp()));

  // Handle "refresh token already used" – Supabase fires signedOut when
  // auto-refresh fails. Clear stale caches so the next login is clean.
  Supabase.instance.client.auth.onAuthStateChange.listen((state) async {
    if (state.event == AuthChangeEvent.signedOut) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) =>
          k.startsWith('profile_map_') || k.startsWith('access_map_')).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    }
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'PoleBarns',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
    );
  }
}
