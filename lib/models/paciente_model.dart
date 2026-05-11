class Paciente {
  final String id;
  final String name;
  final String phone;

  Paciente({required this.id, required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};

  factory Paciente.fromJson(Map<String, dynamic> json) => Paciente(
    // Suporta tanto 'name' (novo) quanto 'nome' (antigo)
    id:
        json['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString(),
    name: (json['name'] ?? json['nome'] ?? 'Paciente').toString(),
    phone: (json['phone'] ?? json['telefone'] ?? '').toString(),
  );
}
