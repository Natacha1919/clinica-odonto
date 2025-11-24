import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provider global para o cliente Supabase
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

// --- Model simples para Paciente ---
// (Usamos uma classe para organizar os dados, é mais seguro que Map)
class Paciente {
  final String id;
  final String nome;
  final String? email;
  final String? telefone;
  final String? cpf;
  final String? dataNascimento;
  final String? status;
  final DateTime criadoEm;

  Paciente({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.cpf,
    this.dataNascimento,
    this.status,
    required this.criadoEm,
  });

  // Converte um Map (vindo do Supabase) para um objeto Paciente
  factory Paciente.fromMap(Map<String, dynamic> map) {
    return Paciente(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String?,
      telefone: map['telefone'] as String?,
      cpf: map['cpf'] as String?,
      dataNascimento: map['data_nascimento'] as String?,
      status: map['status'] as String?,
      criadoEm: DateTime.parse(map['criado_em']),
    );
  }
}

// --- Repositório de Pacientes ---
// (Classe que centraliza as chamadas ao Supabase para pacientes)

class PacientesRepository {
  final SupabaseClient _client;

  // Construtor (deve vir primeiro)
  PacientesRepository(this._client);

  // Cadastrar um novo paciente (versão atualizada)
  Future<void> addPaciente({
    required String nome,
    required String email,
    required String telefone,
    required String cpf,
    required String dataNascimento, // Supabase espera AAAA-MM-DD
    String status = 'aguardando_triagem',
  }) async {
    try {
      await _client.from('pacientes').insert({
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'cpf': cpf,
        'data_nascimento': dataNascimento.isEmpty ? null : dataNascimento,
        'status': status,
        'criado_em': DateTime.now().toIso8601String(),
        'atualizado_em': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erro ao adicionar paciente: $e');
      rethrow;
    }
  }

  // Buscar todos os pacientes (retorna List<Paciente>)
  Future<List<Paciente>> getPacientes() async {
    try {
      final response = await _client
          .from('pacientes')
          .select('*')
          .order('criado_em', ascending: false);

      // Converte a lista de Maps para uma lista de Pacientes
      final pacientes = response.map((map) => Paciente.fromMap(map)).toList();
      return pacientes;
    } catch (e) {
      print('Erro ao buscar pacientes: $e');
      rethrow; // Re-lança o erro para o FutureBuilder/Provider tratar
    }
  }

  // NOVO MÉTODO: Buscar pacientes por status (para a Triagem)
  Future<List<Paciente>> getPacientesPorStatus(String status) async {
    try {
      final response = await _client
          .from('pacientes')
          .select('*')
          .eq('status', status) // Filtro pelo status
          .order('criado_em', ascending: true); // Mais antigos primeiro

      final pacientes = response.map((map) => Paciente.fromMap(map)).toList();
      return pacientes;
    } catch (e) {
      print('Erro ao buscar pacientes por status: $e');
      rethrow;
    }
  }
}

// --- Providers do Riverpod ---

// Provider para o Repositório (para que as telas possam usá-lo)
// (Note que o nome é 'pacientesRepositoryProvider' para ser claro)
final pacientesRepositoryProvider = Provider<PacientesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PacientesRepository(client);
});

// Provider que busca a lista GERAL de pacientes (com cache)
final pacientesListProvider = FutureProvider<List<Paciente>>((ref) {
  final repository = ref.watch(pacientesRepositoryProvider);
  return repository.getPacientes();
});

// NOVO PROVIDER: Provider que busca pacientes AGUARDANDO triagem
final pacientesAguardandoProvider = FutureProvider<List<Paciente>>((ref) {
  final repository = ref.watch(pacientesRepositoryProvider);
  // Busca especificamente este status
  return repository.getPacientesPorStatus('aguardando_triagem');
});