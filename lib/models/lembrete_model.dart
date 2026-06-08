class Lembrete {
  final String? id;
  final String pacienteId;
  final String profissionalId;
  final String titulo;
  final String descricao;
  final DateTime dataLembrete; // ✅ Atualizado
  final bool concluido; // ✅ Novo campo
  final DateTime? createdAt;

  Lembrete({
    this.id,
    required this.pacienteId,
    required this.profissionalId,
    required this.titulo,
    required this.descricao,
    required this.dataLembrete,
    this.concluido = false,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'paciente_id': pacienteId,
    'profissional_id': profissionalId,
    'titulo': titulo,
    'descricao': descricao,
    'data_lembrete': dataLembrete.toIso8601String(), // ✅ Atualizado
    'concluido': concluido,
  };

  factory Lembrete.fromJson(Map<String, dynamic> json) => Lembrete(
    id: json['id']?.toString(),
    pacienteId: json['paciente_id']?.toString() ?? '',
    profissionalId: json['profissional_id']?.toString() ?? '',
    titulo: json['titulo']?.toString() ?? '',
    descricao: json['descricao']?.toString() ?? '',
    dataLembrete:
        json['data_lembrete'] !=
            null // ✅ Atualizado
        ? DateTime.parse(json['data_lembrete'].toString())
        : DateTime.now(),
    concluido: json['concluido'] ?? false,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'].toString())
        : null,
  );
}
