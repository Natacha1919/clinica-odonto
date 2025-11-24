import 'package:clinica_escola_web/features/patients/pages/add_patient_page.dart';
import 'package:clinica_escola_web/features/patients/pages/patient_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// IMPORTANTE: Verifique se os caminhos estão exatos

class PatientsListScreen extends StatefulWidget {
  const PatientsListScreen({super.key});

  @override
  State<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends State<PatientsListScreen> {
  final _supabase = Supabase.instance.client;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Pacientes"),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
        actions: [
          // BOTÃO ADICIONAR PACIENTE
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const AddPatientScreen())
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Novo"),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // BARRA DE PESQUISA
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar por nome...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // LISTA DE PACIENTES
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('pacientes')
                  .stream(primaryKey: ['id'])
                  .order('nome', ascending: true),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Erro: ${snapshot.error}"));
                }

                final allPatients = snapshot.data ?? [];
                
                // Filtro local da busca
                final patients = allPatients.where((p) {
                  final nome = (p['nome'] ?? '').toString().toLowerCase();
                  final cpf = (p['cpf'] ?? '').toString();
                  final query = _searchQuery.toLowerCase();
                  return nome.contains(query) || cpf.contains(query);
                }).toList();

                if (patients.isEmpty) {
                  return const Center(child: Text("Nenhum paciente encontrado."));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: patients.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _buildPatientCard(patients[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // CARD BLINDADO CONTRA ERROS
  Widget _buildPatientCard(Map<String, dynamic> p) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // NAVEGAÇÃO SEGURA
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatientProfileScreen(patient: p),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Text(
                  (p['nome'] ?? '?').toString().substring(0, 1).toUpperCase(),
                  style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              
              // Informações (Usando Expanded para não estourar a tela)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['nome'] ?? 'Sem Nome',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "CPF: ${p['cpf'] ?? '---'}",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Status
              _buildStatusBadge(p['status']),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color = Colors.grey;
    String label = "---";

    if (status == 'espera') {
      color = Colors.orange;
      label = "Fila";
    } else if (status == 'agendado_triagem') {
      color = Colors.blue;
      label = "Agendado";
    } else if (status == 'triagem_realizada') {
      color = Colors.purple;
      label = "Triado";
    } else if (status == 'em_tratamento') {
      color = Colors.green;
      label = "Ativo";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}