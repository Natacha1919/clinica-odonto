import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  // --- FUNÇÃO DE SAIR ---
  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      // Não precisa de context.go('/login') se o Router estiver configurado corretamente (Passo 3)
      // Mas por segurança, podemos forçar se o listener falhar:
      // if (context.mounted) context.go('/login'); 
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao sair")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Identifica a rota atual para destacar no menu
    final String location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: Row(
        children: [
          // MENU LATERAL (SIDEBAR)
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Logo / Título
                const Icon(Icons.local_hospital, size: 40, color: Colors.blue),
                const SizedBox(height: 10),
                const Text("Clínica Escola", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Divider(height: 40),

                // Itens do Menu
                _MenuItem(
                  icon: Icons.dashboard, 
                  label: "Visão Geral", 
                  isSelected: location == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                _MenuItem(
                  icon: Icons.people, 
                  label: "Triagem", 
                  isSelected: location == '/triage',
                  onTap: () => context.go('/triage'),
                ),
                _MenuItem(
                  icon: Icons.person_search, 
                  label: "Pacientes", 
                  isSelected: location.startsWith('/patients'),
                  onTap: () => context.go('/patients'),
                ),
                _MenuItem(
                  icon: Icons.calendar_today, 
                  label: "Agenda", 
                  isSelected: location == '/agenda',
                  onTap: () => context.go('/agenda'),
                ),
                
                const Spacer(), // Empurra o botão Sair para baixo
                
                const Divider(),
                
                // --- BOTÃO SAIR ---
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Sair do Sistema", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () => _signOut(context), // Chama a função de sair
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // CONTEÚDO DA TELA
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

// Widget auxiliar do item de menu
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon, 
    required this.label, 
    required this.isSelected, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(
        label, 
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black87, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.shade50,
      onTap: onTap,
    );
  }
}