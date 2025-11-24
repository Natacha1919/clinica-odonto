import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatefulWidget {
  final Widget child; // O conteúdo da página atual (ex: Dashboard, Triagem)

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Helper para navegar e atualizar o índice
  void _onItemTapped(int index, String routeName, BuildContext context) {
    setState(() {
      _selectedIndex = index;
    });
    context.go(routeName);
  }

  @override
  Widget build(BuildContext context) {
    // Determina o índice selecionado com base na rota atual
    final String currentRoute = GoRouterState.of(context).matchedLocation; // <-- CORREÇÃO AQUI

    if (currentRoute == '/dashboard') {
      _selectedIndex = 0;
    } else if (currentRoute == '/triage') {
      _selectedIndex = 1;
    } else if (currentRoute == '/patients') {
      _selectedIndex = 2;
    } else if (currentRoute == '/agenda') {
      _selectedIndex = 3;
    } else if (currentRoute == '/ehr') {
      _selectedIndex = 4;
    }

    return Scaffold(
      // 1. App Bar Superior (como na imagem)
appBar: AppBar(
  title: const Text(
    'Clínica-Escola - Painel Administrativo',
    style: TextStyle(
      color: Color(0xFF007BFF),
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),
  actions: [
    TextButton(
      onPressed: () {
        // Lógica de logout
        // Ex: ref.read(authProvider.notifier).signOut();
        context.go('/login');
      },
      style: TextButton.styleFrom(
        // Ajuste a cor conforme seu tema
        foregroundColor: Colors.black54, 
      ),
      child: const Text('Sair'),
    ),
    const SizedBox(width: 24), // Espaçamento da borda direita
  ],
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          _buildNavButton(
            context,
            icon: Icons.space_dashboard_outlined,
            label: 'Visão Geral',
            isSelected: _selectedIndex == 0,
            onPressed: () => _onItemTapped(0, '/dashboard', context),
          ),
          const SizedBox(width: 8),
          _buildNavButton(
            context,
            icon: Icons.people_alt_outlined,
            label: 'Triagem',
            isSelected: _selectedIndex == 1,
            onPressed: () => _onItemTapped(1, '/triage', context),
          ),
          const SizedBox(width: 8),
          _buildNavButton(
            context,
            icon: Icons.person_search_outlined,
            label: 'Pacientes',
            isSelected: _selectedIndex == 2,
            onPressed: () => _onItemTapped(2, '/patients', context),
          ),
          const SizedBox(width: 8),
          _buildNavButton(
            context,
            icon: Icons.calendar_month_outlined,
            label: 'Agenda',
            isSelected: _selectedIndex == 3,
            onPressed: () => _onItemTapped(3, '/agenda', context),
          ),
          const SizedBox(width: 8),
          _buildNavButton(
            context,
            icon: Icons.folder_shared_outlined,
            label: 'Prontuários',
            isSelected: _selectedIndex == 4,
            onPressed: () => _onItemTapped(4, '/ehr', context),
          ),
        ],
      ),
    ),
  ),
),
body: widget.child,
    );
  }

  // Widget helper para os botões de navegação
  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    final color = isSelected ? Theme.of(context).primaryColor : Colors.black54;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue.shade50 : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}