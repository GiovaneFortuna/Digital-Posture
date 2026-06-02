import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lembrete_model.dart';
import '../models/paciente_model.dart';

class LembreteService {
  final _supabase = Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  // Busca pacientes do profissional logado
  Future<List<Paciente>> carregarPacientes() async {
    if (_userId == null) return [];

    final response = await _supabase
        .from('pacientes')
        .select()
        .eq('profissional_id', _userId!)
        .eq('ativo', true)
        .order('name', ascending: true);

    return (response as List).map((item) => Paciente.fromJson(item)).toList();
  }

  // Busca lembretes do profissional logado no Supabase
  Future<List<Lembrete>> carregarLembretes() async {
    if (_userId == null) return [];

    final response = await _supabase
        .from('lembretes')
        .select()
        .eq('profissional_id', _userId!)
        .order('created_at', ascending: false);

    return (response as List).map((item) => Lembrete.fromJson(item)).toList();
  }

  // Salva novo lembrete no Supabase
  Future<List<Lembrete>> salvarLembrete({
    required List<Lembrete> lembretesAtuais,
    required String pacienteId,
    required String titulo,
    required String descricao,
    required String horario,
  }) async {
    if (_userId == null) return lembretesAtuais;

    final lembrete = Lembrete(
      pacienteId: pacienteId,
      profissionalId: _userId!,
      titulo: titulo,
      descricao: descricao,
      horario: horario,
    );

    final response = await _supabase
        .from('lembretes')
        .insert(lembrete.toJson())
        .select()
        .single();

    final novoLembrete = Lembrete.fromJson(response);
    return [novoLembrete, ...lembretesAtuais];
  }

  // Deleta lembrete no Supabase
  Future<List<Lembrete>> deletarLembrete({
    required List<Lembrete> lembretesAtuais,
    required String id,
  }) async {
    await _supabase.from('lembretes').delete().eq('id', id);
    return lembretesAtuais.where((l) => l.id != id).toList();
  }

  // Filtra lembretes por paciente
  List<Lembrete> lembretesPorPaciente({
    required List<Lembrete> lembretes,
    required String pacienteId,
  }) {
    return lembretes.where((l) => l.pacienteId == pacienteId).toList();
  }
}
