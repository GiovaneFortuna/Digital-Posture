class Lembrete {
  final String? id;
  final String pacienteId;
  final String profissionalId;
  final String titulo;
  final String descricao;
  final String horario;
  final DateTime? createdAt;

  Lembrete({
    this.id,
    required this.pacienteId,
    required this.profissionalId,
    required this.titulo,
    required this.descricao,
    required this.horario,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'paciente_id': pacienteId,
    'profissional_id': profissionalId,
    'titulo': titulo,
    'descricao': descricao,
    'horario': horario,
  };

  factory Lembrete.fromJson(Map<String, dynamic> json) => Lembrete(
    id: json['id']?.toString(),
    pacienteId: json['paciente_id']?.toString() ?? '',
    profissionalId: json['profissional_id']?.toString() ?? '',
    titulo: json['titulo']?.toString() ?? '',
    descricao: json['descricao']?.toString() ?? '',
    horario: json['horario']?.toString() ?? '',
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'].toString())
        : null,
  );
}
