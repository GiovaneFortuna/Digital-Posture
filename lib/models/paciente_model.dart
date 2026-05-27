class Paciente {
  final String? id;
  final String? profissionalId;
  final String nomeCompleto;
  final int? idade;
  final String? sexo;
  final double? peso;
  final int? altura;
  final String? telefone;
  final bool ativo;
  final DateTime? createdAt;

  Paciente({
    this.id,
    this.profissionalId,
    required this.nomeCompleto,
    this.idade,
    this.sexo,
    this.peso,
    this.altura,
    this.telefone,
    this.ativo = true,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (profissionalId != null) 'profissional_id': profissionalId,
      'name': nomeCompleto,
      'idade': idade,
      'sexo': sexo,
      'peso': peso,
      'altura': altura,
      'telefone': telefone,
      'ativo': ativo,
    };
  }

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id']?.toString(),
      profissionalId: json['profissional_id']?.toString(),
      nomeCompleto: (json['name'] ?? 'Sem nome').toString(),
      idade: int.tryParse(json['idade'].toString()),
      sexo: json['sexo']?.toString(),
      peso: double.tryParse(json['peso'].toString()),
      altura: int.tryParse(json['altura'].toString()),
      telefone: json['telefone']?.toString() ?? '',
      ativo: json['ativo'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : null,
    );
  }
}
