import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/checklist_data.dart';
import '../models/checklist_model.dart';
import '../models/paciente_model.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  static const _green = Color(0xFF00897B);
  static const _greenDark = Color(0xFF00796B);
  static const _greenLight = Color(0xFFE0F2F1);

  final _supabase = Supabase.instance.client;

  late List<ChecklistSection> _sections;
  List<Paciente> _pacientes = [];
  Paciente? _pacienteSelecionado;
  bool _isLoading = true;
  bool _isSaving = false;

  final _observacoesController = TextEditingController();
  final _conclusaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sections = buildInitialSections();
    _loadPacientes();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    _conclusaoController.dispose();
    super.dispose();
  }

  Future<void> _loadPacientes() async {
    setState(() => _isLoading = true);
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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Erro ao carregar pacientes: $e', Colors.red);
      }
    }
  }

  int get _totalSelected =>
      _sections.fold(0, (sum, s) => sum + s.selectedCount);

  // Gera resumo das alterações encontradas
  String _gerarObservacoes() {
    final buffer = StringBuffer();
    for (final section in _sections) {
      final alteracoes = <String>[];
      for (final group in section.groups) {
        if (group.type == SelectionType.radio && group.selected != null) {
          final opt = group.options.firstWhere((o) => o.id == group.selected);
          alteracoes.add('${group.segment}: ${opt.label}');
        } else if (group.type == SelectionType.checkbox &&
            group.checked.isNotEmpty) {
          for (final id in group.checked) {
            final opt = group.options.firstWhere((o) => o.id == id);
            alteracoes.add('${group.segment}: ${opt.label}');
          }
        }
      }
      if (alteracoes.isNotEmpty) {
        buffer.writeln('${section.title}:');
        for (final a in alteracoes) {
          buffer.writeln('  - $a');
        }
      }
    }
    return buffer.toString().trim();
  }

  Future<void> _handleSave() async {
    if (_pacienteSelecionado == null) {
      _showSnackBar('Selecione um paciente antes de salvar!', Colors.red);
      return;
    }

    if (_totalSelected == 0) {
      _showSnackBar('Preencha pelo menos um item do checklist!', Colors.red);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final observacoes = _observacoesController.text.trim().isEmpty
          ? _gerarObservacoes() // ✅ Gera automaticamente se não preenchido
          : _observacoesController.text.trim();

      await _supabase.from('avaliacoes').insert({
        'paciente_id': _pacienteSelecionado!.id,
        'profissional_id': userId,
        'data_avaliacao': DateTime.now().toIso8601String(),
        'status': 'concluida',
        'observacoes': observacoes,
        'conclusao_geral': _conclusaoController.text.trim(),
      });

      if (mounted) {
        _showSnackBar('Avaliação salva com sucesso!', _green);
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar avaliação: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleRadio(
    ChecklistSection section,
    ChecklistGroup group,
    String optionId,
  ) {
    setState(() {
      group.selected = group.selected == optionId ? null : optionId;
    });
  }

  void _handleCheckbox(
    ChecklistSection section,
    ChecklistGroup group,
    String optionId,
  ) {
    setState(() {
      if (group.checked.contains(optionId)) {
        group.checked.remove(optionId);
      } else {
        group.checked.add(optionId);
      }
    });
  }

  void _showSnackBar(String text, Color background) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greenLight,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _green))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    children: [
                      // ── Seletor de Paciente ──────────────────
                      _buildSeletorPaciente(),
                      const SizedBox(height: 16),

                      // ── Seções do Checklist ──────────────────
                      ..._sections.map(_buildSectionCard),

                      // ── Observações ──────────────────────────
                      const SizedBox(height: 8),
                      _buildCampoTexto(
                        controller: _observacoesController,
                        label: 'Observações adicionais',
                        hint: 'Deixe em branco para gerar automaticamente...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      // ── Conclusão Geral ──────────────────────
                      _buildCampoTexto(
                        controller: _conclusaoController,
                        label: 'Conclusão Geral',
                        hint: 'Ex: Paciente apresenta hiperlordose lombar...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ── Seletor de Paciente ───────────────────────────────────────────────────

  Widget _buildSeletorPaciente() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _pacienteSelecionado != null ? _green : Colors.grey[200]!,
          width: _pacienteSelecionado != null ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paciente',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<Paciente>(
              isExpanded: true,
              hint: const Text('Selecione o paciente'),
              value: _pacienteSelecionado,
              items: _pacientes.map((p) {
                return DropdownMenuItem<Paciente>(
                  value: p,
                  child: Text(p.nomeCompleto),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _pacienteSelecionado = value),
            ),
          ),
        ],
      ),
    );
  }

  // ── Campo de texto ────────────────────────────────────────────────────────

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 3,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _green,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8F8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _green),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 12,
        24,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Checklist Digital',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Avaliação postural completa',
            style: TextStyle(color: Color(0xFFB2DFDB), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _greenDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_totalSelected alterações registradas',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              if (_pacienteSelecionado != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _pacienteSelecionado!.nomeCompleto.split(' ').first,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────

  Widget _buildSectionCard(ChecklistSection section) {
    final count = section.selectedCount;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _greenLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          iconColor: _green,
          collapsedIconColor: Colors.grey,
          children: _buildSegmentedGroups(section),
        ),
      ),
    );
  }

  List<Widget> _buildSegmentedGroups(ChecklistSection section) {
    final result = <Widget>[];
    final seen = <String>{};
    for (final g in section.groups) {
      if (!seen.contains(g.segment) || _isNewSegmentBlock(section.groups, g)) {
        seen.add(g.segment);
        result.add(_buildSegmentHeader(g.segment));
      }
      result.add(_buildGroupRow(section, g));
    }
    return result;
  }

  bool _isNewSegmentBlock(List<ChecklistGroup> groups, ChecklistGroup group) {
    final idx = groups.indexOf(group);
    if (idx == 0) return true;
    return groups[idx - 1].segment != group.segment;
  }

  Widget _buildSegmentHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _green,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: _greenLight)),
        ],
      ),
    );
  }

  Widget _buildGroupRow(ChecklistSection section, ChecklistGroup group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: group.options.map((opt) {
          final active = group.type == SelectionType.radio
              ? group.selected == opt.id
              : group.checked.contains(opt.id);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  if (group.type == SelectionType.radio) {
                    _handleRadio(section, group, opt.id);
                  } else {
                    _handleCheckbox(section, group, opt.id);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active ? _green : const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? _green : const Color(0xFFE0E0E0),
                    ),
                    boxShadow: active
                        ? [
                            const BoxShadow(
                              color: Color(0x2200897B),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    opt.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? Colors.white : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Bottom button ─────────────────────────────────────────────────────────

  Widget _buildBottomButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _handleSave,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_outlined, size: 20),
          label: Text(
            _isSaving ? 'Salvando...' : 'Salvar Avaliação',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }
}
