import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart'; // Importante para selecionar arquivos

class PatientProfileScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientProfileScreen({super.key, required this.patient});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _supabase = Supabase.instance.client;
  
  // Futures para carregar dados
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;
  late Future<List<Map<String, dynamic>>> _attachmentsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _appointmentsFuture = _fetchAppointments();
      _attachmentsFuture = _fetchAttachments();
    });
  }

  // --- BANCO DE DADOS ---

  Future<List<Map<String, dynamic>>> _fetchAppointments() async {
    try {
      final response = await _supabase
          .from('agendamentos')
          .select()
          .eq('paciente_id', widget.patient['id'])
          .order('data_consulta', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAttachments() async {
    try {
      final response = await _supabase
          .from('anexos')
          .select()
          .eq('paciente_id', widget.patient['id'])
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // --- UPLOAD DE ARQUIVO ---
  Future<void> _uploadFile() async {
    try {
      // 1. Selecionar Arquivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'doc'], // Tipos permitidos
      );

      if (result != null) {
        // Mostrar loading
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enviando arquivo...")));

        final fileBytes = result.files.first.bytes; // Para Web/Desktop
        final fileName = result.files.first.name;
        final fileExt = fileName.split('.').last;
        
        // Caminho único: ID_PACIENTE / TIMESTAMP_NOME
        final filePath = '${widget.patient['id']}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        // 2. Enviar para o Storage (Bucket)
        // Nota: Usamos uploadBinary para funcionar em Web e Desktop
        if (fileBytes != null) {
          await _supabase.storage.from('documentos_pacientes').uploadBinary(
            filePath,
            fileBytes,
          );
        } else {
           // Fallback se não tiver bytes (raro em versões novas do file_picker)
           throw "Erro ao ler arquivo.";
        }

        // 3. Pegar a URL Pública
        final publicUrl = _supabase.storage.from('documentos_pacientes').getPublicUrl(filePath);

        // 4. Salvar no Banco de Dados
        await _supabase.from('anexos').insert({
          'paciente_id': widget.patient['id'],
          'nome_arquivo': fileName,
          'tipo_arquivo': fileExt,
          'url_storage': publicUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Arquivo anexado com sucesso!"), backgroundColor: Colors.green));
          _refreshData(); // Recarrega a lista
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro no upload: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _openAttachment(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // --- FORMATADORES ---
  String _safeText(dynamic val) => val?.toString() ?? "---";
  String _safeDate(dynamic val) {
    if (val == null) return "---";
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(val.toString())); } catch (e) { return val.toString(); }
  }
  String _safeDateTime(dynamic val) {
    if (val == null) return "---";
    try { return DateFormat('dd/MM HH:mm').format(DateTime.parse(val.toString())); } catch (e) { return val.toString(); }
  }

  Future<void> _openZap() async {
    final phone = widget.patient['telefone']?.toString().replaceAll(RegExp(r'\D'), '');
    if (phone != null && phone.isNotEmpty) {
      final url = Uri.parse("https://wa.me/55$phone");
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

    return DefaultTabController(
      length: 4, // AGORA SÃO 4 ABAS
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text("Prontuário"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        body: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.blue.shade100,
                    child: Text((p['nome'] ?? '?').toString().substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 28, color: Colors.blue.shade900)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_safeText(p['nome']), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text("CPF: ${_safeText(p['cpf'])}"),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(_safeText(p['status']).toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.blue.shade50,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      ],
                    ),
                  ),
                  IconButton.filled(onPressed: _openZap, icon: const Icon(Icons.message), style: IconButton.styleFrom(backgroundColor: Colors.green), tooltip: "WhatsApp")
                ],
              ),
            ),

            // TABS
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                isScrollable: true, // Permite rolar se a tela for pequena
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: "Dados"),
                  Tab(text: "Agenda"),
                  Tab(text: "Evolução"),
                  Tab(text: "Anexos"), // NOVA ABA
                ],
              ),
            ),

            // CONTEÚDO
            Expanded(
              child: TabBarView(
                children: [
                  // ABA 1: DADOS
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSectionTitle("Contato"),
                      _buildInfoTile(Icons.phone, "Telefone", _safeText(p['telefone'])),
                      _buildInfoTile(Icons.cake, "Nascimento", _safeDate(p['data_nascimento'])),
                      _buildInfoTile(Icons.calendar_today, "Cadastro", _safeDate(p['created_at'])),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Clínico"),
                      _buildInfoTile(Icons.medical_services, "Interesse", _safeText(p['servico_interesse']).toUpperCase()),
                    ],
                  ),

                  // ABA 2: AGENDA
                  _buildAppointmentsTab(p),

                  // ABA 3: EVOLUÇÃO
                  const Center(child: Text("Evolução clínica em breve.")),

                  // ABA 4: ANEXOS (Documentos)
                  _buildAttachmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CONSTRUTOR DA ABA DE AGENDAMENTOS ---
  Widget _buildAppointmentsTab(Map<String, dynamic> p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p['data_agendamento'] != null) ...[
            const Text("PRÓXIMO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Card(
              color: Colors.green.shade50,
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.green, size: 32),
                title: Text(_safeDateTime(p['data_agendamento']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                subtitle: const Text("Agendamento Ativo"),
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Text("HISTÓRICO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _appointmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final appointments = snapshot.data ?? [];
              if (appointments.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text("Nenhum histórico.", style: TextStyle(color: Colors.grey)));
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appt = appointments[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: Colors.blue),
                      title: Text(appt['procedimento'] ?? 'Consulta'),
                      subtitle: Text(_safeDateTime(appt['data_consulta'])),
                      trailing: Chip(label: Text(appt['status'] ?? '-'), backgroundColor: Colors.grey.shade100),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- CONSTRUTOR DA ABA DE ANEXOS ---
  Widget _buildAttachmentsTab() {
    return Column(
      children: [
        // Botão de Upload
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploadFile,
              icon: const Icon(Icons.upload_file),
              label: const Text("Adicionar Documento / Exame"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        
        // Lista de Arquivos
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _attachmentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final files = snapshot.data ?? [];

              if (files.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_off, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      const Text("Nenhum anexo encontrado.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: files.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final file = files[index];
                  final type = (file['tipo_arquivo'] ?? '').toString().toLowerCase();
                  
                  // Ícone baseado no tipo
                  IconData icon = Icons.insert_drive_file;
                  Color iconColor = Colors.grey;
                  if (['jpg', 'png', 'jpeg'].contains(type)) {
                    icon = Icons.image;
                    iconColor = Colors.purple;
                  } else if (type == 'pdf') {
                    icon = Icons.picture_as_pdf;
                    iconColor = Colors.red;
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: Icon(icon, color: iconColor, size: 30),
                      title: Text(file['nome_arquivo'] ?? 'Arquivo', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Enviado em: ${_safeDateTime(file['created_at'])}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.blue),
                        onPressed: () => _openAttachment(file['url_storage']),
                        tooltip: "Abrir Arquivo",
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(title, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 16)));
  
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 8), color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(leading: Icon(icon, color: Colors.grey), title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), subtitle: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500))));
  }
  
  Widget _buildStatusChip(String? status) => Chip(label: Text((status ?? '').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), backgroundColor: Colors.grey.shade100);
}