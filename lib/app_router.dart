// lib/app_router.dart
import 'package:clinica_escola_web/core/widgets/main_layout.dart';
import 'package:clinica_escola_web/features/auth/presentation/screens/login_screen.dart';
import 'package:clinica_escola_web/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:clinica_escola_web/features/triage/presentation/screens/triage_screen.dart';
import 'package:clinica_escola_web/features/patients/pages/add_patient_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// APAGUE A LINHA ANTIGA E COLOQUE ESTAS:
import 'package:clinica_escola_web/features/patients/pages/patients_list_screen.dart';


// Provider do Riverpod para o GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          // MainLayout precisa renderizar o 'child'
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
          // Pacientes com rota aninhada "new"
          GoRoute(
            path: '/patients',
            builder: (context, state) => const PatientsListScreen(), // Mudou de Page para Screen
          ),
          GoRoute(
            path: '/patients/new',
            builder: (context, state) => const AddPatientScreen(), // Mudou de Page para Screen
          ),
        ],
      ),
      GoRoute(
        name: 'agenda',
        path: '/agenda',
        builder: (context, state) => const Center(child: Text('Agenda')),
      ),
      GoRoute(
        name: 'ehr',
        path: '/ehr',
        builder: (context, state) => const Center(child: Text('Prontuários')),
      ),
    ],
  );
});