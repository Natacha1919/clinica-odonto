import 'dart:async';

import 'package:clinica_escola_web/core/widgets/main_layout.dart';
import 'package:clinica_escola_web/features/auth/presentation/screens/login_screen.dart';
import 'package:clinica_escola_web/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:clinica_escola_web/features/patients/pages/add_patient_page.dart';
import 'package:clinica_escola_web/features/patients/pages/patients_list_screen.dart';
import 'package:clinica_escola_web/features/triage/presentation/screens/triage_screen.dart' show TriageScreen;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



final routerProvider = Provider<GoRouter>((ref) {
  final supabase = Supabase.instance.client;

  return GoRouter(
    initialLocation: '/dashboard',
    
    // --- O SEGREDO ESTÁ AQUI ---
    // Isso faz o router "ouvir" o Supabase. Se o login mudar, ele recarrega.
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    
    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final isLoggingIn = state.matchedLocation == '/login';

      // Se NÃO tem sessão e NÃO está na tela de login -> Manda pro Login
      if (session == null && !isLoggingIn) return '/login';

      // Se TEM sessão e está tentando acessar o login -> Manda pro Dashboard
      if (session != null && isLoggingIn) return '/dashboard';

      return null; // Tudo certo, segue o fluxo
    },

    routes: [
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            name: 'dashboard',
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            name: 'triage',
            path: '/triage',
            builder: (context, state) => const TriageScreen(),
          ),
          GoRoute(
            path: '/patients',
            builder: (context, state) => const PatientsListScreen(),
          ),
          GoRoute(
            path: '/patients/new',
            builder: (context, state) => const AddPatientScreen(),
          ),
          GoRoute(
            name: 'agenda',
            path: '/agenda',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Agenda em breve'))),
          ),
          GoRoute(
            name: 'ehr',
            path: '/ehr',
            builder: (context, state) => const Scaffold(body: Center(child: Text('Prontuários em breve'))),
          ),
        ],
      ),
    ],
  );
});

// --- CLASSE AUXILIAR OBRIGATÓRIA ---
// Transforma o Stream do Supabase em algo que o GoRouter entende
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}