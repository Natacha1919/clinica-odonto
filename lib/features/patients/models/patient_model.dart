class Patient {
  final String id;
  final String name;
  final String? cpf;
  final String phone;
  final DateTime? birthDate;
  final String status;           // Novo campo
  final String? interestedService; // Novo campo

  Patient({
    required this.id,
    required this.name,
    this.cpf,
    required this.phone,
    this.birthDate,
    required this.status,
    this.interestedService,
  });

  // Factory para converter JSON do Supabase em Objeto Dart
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? '',
      // Ajuste as chaves abaixo conforme o nome exato da coluna no seu Supabase (português)
      name: json['nome'] ?? '', 
      cpf: json['cpf'],
      phone: json['telefone'] ?? '',
      birthDate: json['data_nascimento'] != null 
          ? DateTime.tryParse(json['data_nascimento']) 
          : null,
      status: json['status'] ?? 'espera',
      interestedService: json['servico_interesse'],
    );
  }
}