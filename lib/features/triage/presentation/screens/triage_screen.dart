import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  final _supabase = Supabase.instance.client;

  // --- LÓGICA DO POPUP DE AGENDAMENTO ---
  Future<void> _showScheduleDialog(String patientId, String patientName) async {
    DateTime? pickedDate;
    TimeOfDay? pickedTime;
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Agendar Triagem: $patientName"),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Defina a data e horário para o atendimento."),
                    const SizedBox(height: 20),
                    
                    // Seletores de Data e Hora
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(pickedDate == null 
                                ? "Data" 
                                : DateFormat('dd/MM/yyyy').format(pickedDate!)),
                            leading: const Icon(Icons.calendar_today, color: Colors.blue),
                            tileColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 60)),
                              );
                              if (date != null) setStateDialog(() => pickedDate = date);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ListTile(
                            title: Text(pickedTime == null 
                                ? "Hora" 
                                : pickedTime!.format(context)),
                            leading: const Icon(Icons.access_time, color: Colors.orange),
                            tileColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: const TimeOfDay(hour: 8, minute: 0),
                              );
                              if (time != null) setStateDialog(() => pickedTime = time);
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Observações (Opcional)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Confirmar Agendamento"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  // Só habilita o botão se data e hora forem escolhidas
                  onPressed: (pickedDate != null && pickedTime != null) 
                    ? () {
                        Navigator.pop(ctx);
                        _saveSchedule(patientId, pickedDate!, pickedTime!, notesController.text);
                      } 
                    : null,
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FUNÇÃO QUE MOVE O PACIENTE (UPDATE) ---
  Future<void> _saveSchedule(String id, DateTime date, TimeOfDay time, String notes) async {
    try {
      // Cria a data completa combinando dia e hora
      final finalDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

      print("Tentando mover paciente $id para 'agendado_triagem'...");

      // Atualiza no Supabase
      await _supabase.from('pacientes').update({
        'status': 'agendado_triagem', // O STATUS QUE A LISTA DA DIREITA ESPERA
        'data_agendamento': finalDateTime.toIso8601String(),
      }).eq('id', id);

      print("Sucesso! Paciente movido.");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Agendamento realizado! Paciente movido para a lista da direita."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("ERRO AO SALVAR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao salvar: Verifique se o status 'agendado_triagem' existe no banco."), 
            backgroundColor: Colors.red
          ),
        );
      }
    }
  }

  // Formatação de Data
  String _formatDate(String? isoString) {
    if (isoString == null) return "--";
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM HH:mm').format(date);
    } catch (e) {
      return isoString;
    }
  }

  // Formatação de Serviço
  String _formatService(String? service) {
    if (service == null) return "Geral";
    return service.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Central de Triagem"),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Row(
        children: [
          // ==================================================
          // LADO ESQUERDO: FILA DE ESPERA
          // ==================================================
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("Fila de Espera", Icons.inbox, Colors.blueGrey, "Novos cadastros"),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildPatientList(
                      statusFilter: 'espera', // Filtra quem acabou de chegar
                      emptyMessage: "Nenhum novo paciente.",
                      isActionSide: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const VerticalDivider(width: 1),

          // ==================================================
          // LADO DIREITO: TRIAGENS AGENDADAS
          // ==================================================
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader("Triagens Agendadas", Icons.calendar_month, Colors.green, "Aguardando comparecimento"),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _buildPatientList(
                      statusFilter: 'agendado_triagem', // Filtra quem já foi agendado
                      emptyMessage: "Nenhuma triagem agendada.",
                      isActionSide: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildHeader(String title, IconData icon, Color color, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildPatientList({
    required String statusFilter,
    required String emptyMessage,
    required bool isActionSide,
  }) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('pacientes')
          .stream(primaryKey: ['id'])
          .eq('status', statusFilter) // AQUI É O FILTRO IMPORTANTE
          // Ordenamos por created_at nos dois lados para garantir que não dê erro de coluna
          .order('created_at', ascending: true), 
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text("Erro: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
        }

        final patients = snapshot.data ?? [];

        if (patients.isEmpty) {
          return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final p = patients[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                // Avatar muda de cor dependendo do lado
                leading: CircleAvatar(
                  backgroundColor: isActionSide ? Colors.blue.shade50 : Colors.green.shade50,
                  foregroundColor: isActionSide ? Colors.blue : Colors.green,
                  child: Text((p['nome'] ?? '?')[0].toUpperCase()),
                ),
                title: Text(p['nome'] ?? 'Sem Nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                
                subtitle: isActionSide 
                  ? Text("Interesse: ${p['servico_interesse'] ?? 'Geral'}")
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Destaque para a data do agendamento no lado direito
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: Text(
                            "Agendado: ${_formatDate(p['data_agendamento'])}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 12),
                          ),
                        ),
                        if (p['telefone'] != null) Text("Tel: ${p['telefone']}"),
                      ],
                    ),
                
                // Botão Agendar na esquerda, Ícone na direita
                trailing: isActionSide
                    ? ElevatedButton(
                        onPressed: () => _showScheduleDialog(p['id'], p['nome'] ?? ''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, 
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12)
                        ),
                        child: const Text("Agendar"),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.grey),
                        tooltip: "Iniciar Atendimento Clínico",
                        onPressed: () {
                          // Futuro: Navegar para a tela de atendimento do dentista
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }
}