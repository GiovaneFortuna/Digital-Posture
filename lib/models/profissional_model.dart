class ProfissionalModel {
  final String id;
  final String nome;
  final String email;
  final DateTime? criadoEm;

  ProfissionalModel({
    required this.id,
    required this.nome,
    required this.email,
    this.criadoEm,
  });

  /// Converte o JSON vindo do Supabase (snake_case) para o objeto Dart (camelCase)
  factory ProfissionalModel.fromJson(Map<String, dynamic> json) {
    return ProfissionalModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      criadoEm: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Converte o objeto Dart de volta para o formato JSON (snake_case) para salvar no Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      // O 'created_at' geralmente é gerado automaticamente pelo banco de dados
    };
  }

  /// Método auxiliar para clonar o objeto caso precise alterar algum dado (ex: atualizar o nome)
  ProfissionalModel copyWith({
    String? id,
    String? nome,
    String? email,
    DateTime? criadoEm,
  }) {
    return ProfissionalModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      criadoEm: criadoEm ?? this.criadoEm,
    );
  }
}
