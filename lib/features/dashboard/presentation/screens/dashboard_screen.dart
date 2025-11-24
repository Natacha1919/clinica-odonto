import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Variáveis para armazenar os números
  int _totalPacientes = 0;
  int _aguardandoTriagem = 0;
  int _consultasHoje = 0;
  int _pacientesAtivos = 0;
  int _pacientesTriados = 0;
  int _totalProntuarios = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Definindo o intervalo de "Hoje" para consulta
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

      // Executando todas as consultas em paralelo (Future.wait) para ser rápido
      // Executando todas as consultas em paralelo (Future.wait) para ser rápido
      final results = await Future.wait<dynamic>([
        // 0: Total de Pacientes (Seleciona tudo e conta)
_supabase.from('pacientes').select('*').count(CountOption.exact),
        
        // 1: Aguardando Triagem
        _supabase.from('pacientes').select('*').eq('status', 'espera').count(CountOption.exact),
        
        // 2: Consultas Hoje (Agendamentos de triagem)
        _supabase.from('pacientes')
            .select('*')
            .gte('data_agendamento', startOfDay) // Maior ou igual 00:00
            .lte('data_agendamento', endOfDay)   // Menor ou igual 23:59
            .count(CountOption.exact),

        // 3: Pacientes Ativos (Quem não está na espera)
        _supabase.from('pacientes').select('*').neq('status', 'espera').count(CountOption.exact),

        // 4: Pacientes Triados (Agendados)F
        _supabase.from('pacientes')
            .select('*')
            .eq('status', 'agendado_triagem')
            .count(CountOption.exact),
      ]);
      // Atualizando o estado com os resultados
      if (mounted) {
        setState(() {
          _totalPacientes = results[0].count;
          _aguardandoTriagem = results[1].count;
          _consultasHoje = results[2].count;
          _pacientesAtivos = results[3].count;
          _pacientesTriados = results[4].count;
          _totalProntuarios = results[0].count; // Cada paciente tem um prontuário
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao carregar dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Visão geral das atividades da clínica", 
                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: "Atualizar Dados",
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Grid Responsivo
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Se a tela for larga (> 800px), usa 3 colunas. Senão, usa 1 ou 2.
                      int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                      
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.4, // Formato retangular do card
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          // LINHA 1
                          _DashboardCard(
                            title: "TOTAL DE PACIENTES",
                            value: _totalPacientes.toString(),
                            subtitle: "Cadastrados no sistema",
                            icon: Icons.people_outline,
                            color: Colors.blue,
                          ),
                          _DashboardCard(
                            title: "AGUARDANDO TRIAGEM",
                            value: _aguardandoTriagem.toString(),
                            subtitle: "Pacientes pendentes",
                            icon: Icons.hourglass_empty,
                            color: Colors.orange,
                          ),
                          _DashboardCard(
                            title: "CONSULTAS HOJE",
                            value: _consultasHoje.toString(),
                            subtitle: "Agendadas para hoje",
                            icon: Icons.calendar_today,
                            color: Colors.green,
                          ),

                          // LINHA 2
                          _DashboardCard(
                            title: "PACIENTES ATIVOS",
                            value: _pacientesAtivos.toString(),
                            subtitle: "Em atendimento",
                            icon: Icons.trending_up,
                            color: Colors.teal,
                          ),
                          _DashboardCard(
                            title: "PACIENTES TRIADOS",
                            value: _pacientesTriados.toString(),
                            subtitle: "Prontos para atendimento",
                            icon: Icons.playlist_add_check,
                            color: Colors.purple,
                          ),
                          _DashboardCard(
                            title: "PRONTUÁRIOS",
                            value: _totalProntuarios.toString(),
                            subtitle: "Total registrados",
                            icon: Icons.folder_shared_outlined,
                            color: Colors.redAccent,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

// --- WIDGET DO CARD INDIVIDUAL ---
class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Título e Subtítulo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            // Rodapé do Card com Ícone e Subtítulo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                Icon(icon, color: color, size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }
}