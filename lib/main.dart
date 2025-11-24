import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:clinica_escola_web/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // ATENÇÃO: Substitua pelas suas chaves do Supabase
  await Supabase.initialize(
    url: 'https://rppaysohvlkujhkjgeus.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwcGF5c29odmxrdWpoa2pnZXVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxOTEzMzYsImV4cCI6MjA3Nzc2NzMzNn0.9bUWGwbb8WP6vwadbWDsmrs6LeSewriaFkRv9J5dGtg',
  );

// Força o logout e ESPERA (await) ele terminar antes de rodar o app.
  // Isso garante que o AppRouter inicie sem usuário logado.
  try {
    await Supabase.instance.client.auth.signOut();
  } catch (e) {
    // Ignora erro se já estiver deslogado
  }

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Clínica-Escola',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
      ),
      routerConfig: router,
    );
  }
}