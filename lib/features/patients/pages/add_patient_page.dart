import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para filtros de texto se não tiver máscaras
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  // Controladores
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthController = TextEditingController();
  String _selectedService = 'canal'; // Valor padrão

  // Máscaras (Visual)
  final maskCpf = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final maskPhone = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final maskDate = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});

  // Lista de Serviços (Igual ao Banco de Dados)
  final List<String> _services = [
    'canal',
    'restauracao',
    'lesao_boca',
    'cirurgia',
    'gengivas',
    'outro',
  ];

  // --- FUNÇÃO DE SALVAR ---
  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Limpar formatação para enviar apenas números
      final cpfClean = _cpfController.text.replaceAll(RegExp(r'\D'), '');
      final phoneClean = _phoneController.text.replaceAll(RegExp(r'\D'), '');

      // 2. Converter Data (DD/MM/AAAA -> AAAA-MM-DD)
      String? birthDateFormatted;
      if (_birthController.text.length == 10) {
        final parts = _birthController.text.split('/'); // [DD, MM, AAAA]
        birthDateFormatted = "${parts[2]}-${parts[1]}-${parts[0]}";
      }

      // 3. ENVIAR PARA O SUPABASE
      await _supabase.from('pacientes').insert({
        'nome': _nameController.text,
        'cpf': cpfClean,
        'telefone': phoneClean,
        'data_nascimento': birthDateFormatted,
        'servico_interesse': _selectedService,
        
        // --- O PULO DO GATO ESTÁ AQUI ---
        // Ao definir 'espera', ele cai automaticamente na Triagem (Lado Esquerdo)
        'status': 'espera', 
        
        // Data de hoje para ordenar a fila
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Paciente cadastrado! Enviado para a Fila de Triagem."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Volta para a tela anterior
      }
    } catch (e) {
      if (mounted) {
        // Tratamento de erro de CPF duplicado
        String msg = "Erro ao salvar: $e";
        if (e.toString().contains("23505")) { // Código Postgres para Unique Violation
          msg = "Este CPF já está cadastrado no sistema.";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper para formatar texto do Dropdown
  String _formatLabel(String s) => s.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Novo Paciente"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Dados Pessoais", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Nome
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration("Nome Completo", Icons.person),
                validator: (v) => v == null || v.isEmpty ? "Campo obrigatório" : null,
              ),
              const SizedBox(height: 16),

              // CPF
              TextFormField(
                controller: _cpfController,
                inputFormatters: [maskCpf],
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("CPF", Icons.badge),
                validator: (v) => v == null || v.length < 14 ? "CPF incompleto" : null,
              ),
              const SizedBox(height: 16),

              // Telefone
              TextFormField(
                controller: _phoneController,
                inputFormatters: [maskPhone],
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("Telefone / WhatsApp", Icons.phone),
                validator: (v) => v == null || v.length < 14 ? "Telefone incompleto" : null,
              ),
              const SizedBox(height: 16),

              // Data de Nascimento
              TextFormField(
                controller: _birthController,
                inputFormatters: [maskDate],
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Data de Nascimento", Icons.cake, hint: "DD/MM/AAAA"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Campo obrigatório";
                  if (v.length < 10) return "Data incompleta";
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              const Text("Triagem Inicial", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Dropdown Serviço
              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: _inputDecoration("Interesse Principal", Icons.medical_services),
                items: _services.map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(_formatLabel(s)),
                )).toList(),
                onChanged: (val) => setState(() => _selectedService = val!),
              ),

              const SizedBox(height: 40),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _savePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? "Salvando..." : "CADASTRAR E ENVIAR PARA FILA"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}