import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sclcfqcjcjpthodutpyc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNjbGNmcWNqY2pwdGhvZHV0cHljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNjA3MzksImV4cCI6MjA4MTYzNjczOX0.HV6KT56OE9GIOTRWwVIfst1QAg-jIqX8loBleldBWb0',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      title: 'Cliente App',
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
    );
  }
}
