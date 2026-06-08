import 'package:flutter/material.dart';
import '../models/lembrete_model.dart';
import '../models/paciente_model.dart';
import '../services/lembrete_service.dart';

class LembretesScreen extends StatefulWidget {
  const LembretesScreen({super.key});

  @override
  State<LembretesScreen> createState() => _LembretesScreenState();
}

class _LembretesScreenState extends State<LembretesScreen> {
  final _service = LembreteService();

  List<Paciente> patients = [];
  List<Lembrete> lembretes = [];
  String? selectedPatientId;
  bool _isLoading = true;

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  DateTime? _dataLembreteSelecionada;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final loadedPatients = await _service.carregarPacientes();
      final loadedLembretes = await _service.carregarLembretes();

      if (mounted) {
        setState(() {
          patients = loadedPatients;
          lembretes = loadedLembretes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Erro ao carregar dados: $e', Colors.red);
      }
    }
  }

  List<Lembrete> get _lembretesDoPackiente {
    if (selectedPatientId == null) return [];
    return _service.lembretesPorPaciente(
      lembretes: lembretes,
      pacienteId: selectedPatientId!,
    );
  }

  Future<void> _salvarLembrete() async {
    if (selectedPatientId == null) {
      _showSnackBar('Por favor, selecione um paciente primeiro.', Colors.red);
      return;
    }
    if (_tituloController.text.isEmpty) {
      _showSnackBar('Por favor, insira um título para o lembrete.', Colors.red);
      return;
    }
    if (_dataLembreteSelecionada == null) {
      _showSnackBar('Por favor, selecione a data e horário.', Colors.red);
      return;
    }

    try {
      final updatedLembretes = await _service.salvarLembrete(
        lembretesAtuais: lembretes,
        pacienteId: selectedPatientId!,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        dataLembrete: _dataLembreteSelecionada!,
      );

      if (mounted) {
        setState(() {
          lembretes = updatedLembretes;
          _tituloController.clear();
          _descricaoController.clear();
          _dataLembreteSelecionada = null;
        });
        _showSnackBar('Lembrete salvo com sucesso!', const Color(0xFF00897B));
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar lembrete: $e', Colors.red);
    }
  }

  Future<void> _deletarLembrete(String id) async {
    try {
      final updatedLembretes = await _service.deletarLembrete(
        lembretesAtuais: lembretes,
        id: id,
      );
      setState(() => lembretes = updatedLembretes);
    } catch (e) {
      _showSnackBar('Erro ao deletar lembrete: $e', Colors.red);
    }
  }

  Future<void> _concluirLembrete(String id) async {
    try {
      final updatedLembretes = await _service.concluirLembrete(
        lembretesAtuais: lembretes,
        id: id,
      );
      setState(() => lembretes = updatedLembretes);
    } catch (e) {
      _showSnackBar('Erro ao concluir lembrete: $e', Colors.red);
    }
  }

  void _showSnackBar(String text, Color background) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: background));
  }

  // ✅ Seleciona data e hora juntos
  Future<void> _selecionarDataHora(StateSetter setModalState) async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF00897B)),
        ),
        child: child!,
      ),
    );

    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF00897B)),
        ),
        child: child!,
      ),
    );

    if (hora == null) return;

    final dataHora = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );

    setModalState(() => _dataLembreteSelecionada = dataHora);
    setState(() => _dataLembreteSelecionada = dataHora);
  }

  String _formatarDataHora(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  void _abrirFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Novo Lembrete',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Título',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tituloController,
                decoration: InputDecoration(
                  hintText: 'Ex: Fazer exercícios de postura',
                  filled: true,
                  fillColor: Colors.grey[50],
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
                    borderSide: const BorderSide(color: Color(0xFF00897B)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Descrição',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Detalhes do lembrete...',
                  filled: true,
                  fillColor: Colors.grey[50],
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
                    borderSide: const BorderSide(color: Color(0xFF00897B)),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data e Horário',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selecionarDataHora(setModalState),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _dataLembreteSelecionada != null
                          ? const Color(0xFF00897B)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _dataLembreteSelecionada != null
                            ? _formatarDataHora(_dataLembreteSelecionada!)
                            : 'Selecionar data e horário',
                        style: TextStyle(
                          fontSize: 14,
                          color: _dataLembreteSelecionada != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarLembrete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Salvar Lembrete',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
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
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lembretes',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Lembretes por paciente',
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00897B),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFF00897B),
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            const Text(
                              'Selecionar Paciente',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (patients.isEmpty)
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
                              ...patients.map((patient) {
                                final isSelected =
                                    selectedPatientId == patient.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => selectedPatientId = patient.id,
                                    ),
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
                                            radius: 24,
                                            backgroundColor: isSelected
                                                ? const Color(0xFF00897B)
                                                : Colors.grey[400],
                                            child: Text(
                                              _getInitial(patient.nomeCompleto),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              patient.nomeCompleto.isNotEmpty
                                                  ? patient.nomeCompleto
                                                  : 'Paciente',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF00897B),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 24),
                            if (selectedPatientId != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Lembretes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _abrirFormulario,
                                    icon: const Icon(
                                      Icons.add,
                                      color: Color(0xFF00897B),
                                    ),
                                    label: const Text(
                                      'Novo',
                                      style: TextStyle(
                                        color: Color(0xFF00897B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_lembretesDoPackiente.isEmpty)
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
                                        Icons.notifications_none,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Nenhum lembrete para este paciente.',
                                        style: TextStyle(color: Colors.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._lembretesDoPackiente.map((lembrete) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: lembrete.concluido
                                            ? Colors.grey[50]
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: lembrete.concluido
                                                  ? Colors.grey[200]
                                                  : const Color(0xFFE0F2F1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              lembrete.concluido
                                                  ? Icons.check_circle
                                                  : Icons
                                                        .notifications_outlined,
                                              color: lembrete.concluido
                                                  ? Colors.grey
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
                                                  lembrete.titulo,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: lembrete.concluido
                                                        ? Colors.grey
                                                        : Colors.black87,
                                                    decoration:
                                                        lembrete.concluido
                                                        ? TextDecoration
                                                              .lineThrough
                                                        : null,
                                                  ),
                                                ),
                                                if (lembrete
                                                    .descricao
                                                    .isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    lembrete.descricao,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Color(0xFF00897B),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _formatarDataHora(
                                                        lembrete.dataLembrete,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF00897B,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              if (!lembrete.concluido)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.check_circle_outline,
                                                    color: Color(0xFF00897B),
                                                  ),
                                                  onPressed: () =>
                                                      _concluirLembrete(
                                                        lembrete.id!,
                                                      ),
                                                ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () =>
                                                    _deletarLembrete(
                                                      lembrete.id!,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
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
