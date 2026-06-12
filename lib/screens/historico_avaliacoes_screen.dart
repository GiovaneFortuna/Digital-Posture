import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paciente_model.dart';
import 'detalhe_avaliacao_screen.dart';

class HistoricoAvaliacoesScreen extends StatefulWidget {
  const HistoricoAvaliacoesScreen({super.key});

  @override
  State<HistoricoAvaliacoesScreen> createState() =>
      _HistoricoAvaliacoesScreenState();
}

class _HistoricoAvaliacoesScreenState extends State<HistoricoAvaliacoesScreen> {
  final _supabase = Supabase.instance.client;

  List<Paciente> _pacientes = [];
  Paciente? _pacienteSelecionado;
  List<Map<String, dynamic>> _avaliacoes = [];
  bool _isLoadingPacientes = true;
  bool _isLoadingAvaliacoes = false;

  @override
  void initState() {
    super.initState();
    _loadPacientes();
  }

  Future<void> _loadPacientes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('pacientes')
          .select()
          .eq('profissional_id', userId)
          .eq('ativo', true)
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _pacientes = (response as List)
              .map((item) => Paciente.fromJson(item))
              .toList();
          _isLoadingPacientes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPacientes = false);
        _showSnackBar('Erro ao carregar pacientes: $e', Colors.red);
      }
    }
  }

  Future<void> _loadAvaliacoes(String pacienteId) async {
    setState(() => _isLoadingAvaliacoes = true);
    try {
      final response = await _supabase
          .from('avaliacoes')
          .select()
          .eq('paciente_id', pacienteId)
          .order('data_avaliacao', ascending: false);

      if (mounted) {
        setState(() {
          _avaliacoes = List<Map<String, dynamic>>.from(response);
          _isLoadingAvaliacoes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAvaliacoes = false);
        _showSnackBar('Erro ao carregar avaliações: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String text, Color background) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: background));
  }

  String _formatarData(String? dataStr) {
    if (dataStr == null) return 'Data desconhecida';
    final data = DateTime.tryParse(dataStr);
    if (data == null) return 'Data inválida';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2F1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF00796B)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.history, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Histórico',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Avaliações por paciente',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFFE0F2F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Conteúdo ────────────────────────────────────────
              Expanded(
                child: _isLoadingPacientes
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00897B),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPacientes,
                        color: const Color(0xFF00897B),
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            // ── Seletor de paciente ──────────────
                            const Text(
                              'Selecionar Paciente',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_pacientes.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: const Text(
                                  'Nenhum paciente cadastrado ainda.',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ...(_pacientes.map((patient) {
                                final isSelected =
                                    _pacienteSelecionado?.id == patient.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _pacienteSelecionado = patient;
                                        _avaliacoes = [];
                                      });
                                      _loadAvaliacoes(patient.id!);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFE0F2F1)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF00897B)
                                              : Colors.grey[200]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: isSelected
                                                ? const Color(0xFF00897B)
                                                : Colors.grey[400],
                                            child: Text(
                                              patient.nomeCompleto.isNotEmpty
                                                  ? patient.nomeCompleto[0]
                                                        .toUpperCase()
                                                  : 'P',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              patient.nomeCompleto,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF00897B),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              })),

                            // ── Lista de avaliações ──────────────
                            if (_pacienteSelecionado != null) ...[
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Avaliações',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${_avaliacoes.length} registro(s)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isLoadingAvaliacoes)
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00897B),
                                  ),
                                )
                              else if (_avaliacoes.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Nenhuma avaliação encontrada.',
                                        style: TextStyle(color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...(_avaliacoes.map((avaliacao) {
                                  final temAlteracoes =
                                      avaliacao['conclusao_geral']
                                          ?.toString()
                                          .contains('Alterações') ??
                                      false;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DetalheAvaliacaoScreen(
                                                  avaliacao: avaliacao,
                                                  nomePaciente:
                                                      _pacienteSelecionado!
                                                          .nomeCompleto,
                                                ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              // ignore: deprecated_member_use
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: temAlteracoes
                                                    ? const Color(0xFFFFEBEE)
                                                    : const Color(0xFFE0F2F1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                temAlteracoes
                                                    ? Icons.warning_outlined
                                                    : Icons
                                                          .check_circle_outline,
                                                color: temAlteracoes
                                                    ? Colors.red[400]
                                                    : const Color(0xFF00897B),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    avaliacao['conclusao_geral']
                                                            ?.toString() ??
                                                        'Avaliação',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _formatarData(
                                                      avaliacao['data_avaliacao'],
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(
                                              Icons.chevron_right,
                                              color: Colors.grey,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                })),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
