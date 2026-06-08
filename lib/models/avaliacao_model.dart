class Avaliacao {
  final String? id;
  final String pacienteId;
  final String profissionalId;
  final DateTime dataAvaliacao;
  final String status;
  final String observacoes;
  final String conclusaoGeral;
  final String? fotoUrl;

  Avaliacao({
    this.id,
    required this.pacienteId,
    required this.profissionalId,
    required this.dataAvaliacao,
    required this.status,
    required this.observacoes,
    required this.conclusaoGeral,
    this.fotoUrl,
  });

  Map<String, dynamic> toJson() => {
    'paciente_id': pacienteId,
    'profissional_id': profissionalId,
    'data_avaliacao': dataAvaliacao.toIso8601String(),
    'status': status,
    'observacoes': observacoes,
    'conclusao_geral': conclusaoGeral,
    if (fotoUrl != null) 'foto_url': fotoUrl,
  };

  factory Avaliacao.fromJson(Map<String, dynamic> json) => Avaliacao(
    id: json['id']?.toString(),
    pacienteId: json['paciente_id']?.toString() ?? '',
    profissionalId: json['profissional_id']?.toString() ?? '',
    dataAvaliacao: json['data_avaliacao'] != null
        ? DateTime.parse(json['data_avaliacao'].toString())
        : DateTime.now(),
    status: json['status']?.toString() ?? '',
    observacoes: json['observacoes']?.toString() ?? '',
    conclusaoGeral: json['conclusao_geral']?.toString() ?? '',
    fotoUrl: json['foto_url']?.toString(),
  );
}
