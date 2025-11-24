import 'package:clinica_escola_web/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ATENÇÃO: Substitua pelas suas chaves do Supabase
  await Supabase.initialize(
    url: 'https://rppaysohvlkujhkjgeus.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwcGF5c29odmxrdWpoa2pnZXVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxOTEzMzYsImV4cCI6MjA3Nzc2NzMzNn0.9bUWGwbb8WP6vwadbWDsmrs6LeSewriaFkRv9J5dGtg',
  );

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
      title: 'Clínica-Escola - Painel Administrativo',
      // Vamos definir um tema limpo
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        
        // CORRETO: Mantenha 'CardThemeData' como você tinha
        cardTheme: CardThemeData( 
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
        ),
 appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Colors.blue.shade50,
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ), // CORREÇÃO: Este ')' estava comentado na sua linha 55
      ), // CORREÇÃO: Este ')' estava comentado na sua linha 56
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    ); // CORREÇÃO: Este ')' fecha o MaterialApp.router
  }
}

// Helper para acessar o cliente Supabase globalmente
final supabaseClientProvider = Provider((ref) => Supabase.instance.client);