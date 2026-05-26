class Paciente {
  final String? id;
  final String profissionalId;
  final String nomeCompleto;
  final String idade; // Mantido como String para bater com o VARCHAR do banco
  final String sexo;
  final double pesoKg; // Alterado para double para bater com o DECIMAL do banco
  final double altura; // Alterado para double para bater com o DECIMAL do banco
  final String telefone;
  final DateTime? createdAt;

  Paciente({
    this.id,
    required this.profissionalId,
    required this.nomeCompleto,
    required this.idade,
    required this.sexo,
    required this.pesoKg,
    required this.altura,
    required this.telefone,
    this.createdAt,
  });

  /// Converte o objeto Paciente em um Map (JSON) para enviar ao Supabase.
  /// As chaves deste Map devem ser EXATAMENTE iguais aos nomes das colunas no banco.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'profissional_id': profissionalId,
      'nome_completo': nomeCompleto,
      'idade': idade,
      'sexo': sexo,
      'peso_kg': pesoKg,
      'altura': altura,
    };

    // Só adiciona o id se ele não for nulo (caso de update)
    if (id != null) {
      data['id'] = id;
    }

    // Só adiciona o telefone se ele tiver sido preenchido
    data['telefone'] = telefone;
  
    return data;
  }

  /// Mapeia o JSON que vem do Supabase de volta para um objeto Paciente do Flutter.
  /// Inclui fallbacks (valores padrão) para evitar erros de Null Safety.
  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id']?.toString(),
      profissionalId: json['profissional_id']?.toString() ?? '',
      // O fallback abaixo aceita tanto a coluna nova do banco quanto as chaves antigas se houver cache local
      nomeCompleto:
          (json['nome_completo'] ??
                  json['name'] ??
                  json['nome'] ??
                  'Paciente Sem Nome')
              .toString(),
      idade: (json['idade'] ?? '').toString(),
      sexo: (json['sexo'] ?? '').toString(),
      // Converte valores numéricos vindos do banco de forma segura para double
      pesoKg: double.tryParse(json['peso_kg'].toString()) ?? 0.0,
      altura: double.tryParse(json['altura'].toString()) ?? 0.0,
      telefone: json['telefone']?.toString() ?? json['phone']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
    );
  }
}
