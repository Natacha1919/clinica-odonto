import 'dart:html' as html;

import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:clinica_escola_web/app_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // ATENÇÃO: Substitua pelas suas chaves do Supabase
  await Supabase.initialize(
    url: 'https://rppaysohvlkujhkjgeus.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwcGF5c29odmxrdWpoa2pnZXVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxOTEzMzYsImV4cCI6MjA3Nzc2NzMzNn0.9bUWGwbb8WP6vwadbWDsmrs6LeSewriaFkRv9J5dGtg',
  );

// 2. LIMPEZA NUCLEAR (Segurança para Quiosque/Clínica)
  // Se estiver na Web, limpa o LocalStorage para remover tokens antigos
  if (kIsWeb) {
    try {
      // Acessa o armazenamento do navegador e apaga chaves do Supabase
      html.window.localStorage.removeWhere((key, value) => key.startsWith('sb-'));
      print("🧹 [Web] Memória do navegador limpa: Tokens removidos.");
    } catch (e) {
      print("⚠️ [Web] Não foi possível limpar storage: $e");
    }
  }

  // 3. FORÇAR LOGOUT NO SDK
  // Garante que a memória RAM do app também esteja limpa
  try {
    await Supabase.instance.client.auth.signOut();
    print("🔒 [Auth] SignOut forçado executado.");
  } catch (e) {
    // Ignora erro se já estiver deslogado
  }

  // 4. INICIALIZAÇÃO DO HIVE (Banco de dados local)
  if (!kIsWeb) {
    // No Windows/Android precisa de um caminho físico
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
  } else {
    // Na Web o Hive usa o IndexedDB automaticamente
    await Hive.initFlutter();
  }

  // Registre seus adaptadores do Hive aqui se tiver (ex: TransactionAdapter)
  // Hive.registerAdapter(...);

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
    // O Router ouve o Supabase (configurado no app_router.dart)
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Clínica-Escola',
      debugShowCheckedModeBanner: false,
      
      // TEMA DO SISTEMA
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC), // Fundo cinza azulado suave
        
        // Padrão para Cards
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
        ),
        
        // Padrão para AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          centerTitle: false,
        ),
      ),
      
      routerConfig: router,
    );
  }
}

// Helper global para acessar o Supabase em qualquer lugar
final supabaseClientProvider = Provider((ref) => Supabase.instance.client);