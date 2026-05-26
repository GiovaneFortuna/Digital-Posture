import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/paciente_model.dart';

class Lembrete {
  final String id;
  final String pacienteId;
  final String titulo;
  final String descricao;
  final String horario;
  final String dataCriacao;

  Lembrete({
    required this.id,
    required this.pacienteId,
    required this.titulo,
    required this.descricao,
    required this.horario,
    required this.dataCriacao,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pacienteId': pacienteId,
    'titulo': titulo,
    'descricao': descricao,
    'horario': horario,
    'dataCriacao': dataCriacao,
  };

  factory Lembrete.fromJson(Map<String, dynamic> json) => Lembrete(
    id: json['id'] ?? '',
    pacienteId: json['pacienteId'] ?? '',
    titulo: json['titulo'] ?? '',
    descricao: json['descricao'] ?? '',
    horario: json['horario'] ?? '',
    dataCriacao: json['dataCriacao'] ?? '',
  );
}

class LembretesScreen extends StatefulWidget {
  const LembretesScreen({super.key});

  @override
  State<LembretesScreen> createState() => _LembretesScreenState();
}

class _LembretesScreenState extends State<LembretesScreen> {
  List<Paciente> patients = [];
  List<Lembrete> lembretes = [];
  String? selectedPatientId;
  bool _isLoading = true;

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  TimeOfDay? _horarioSelecionado;

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
    final prefs = await SharedPreferences.getInstance();

    final pacientesJson = prefs.getStringList('pacientes') ?? [];
    final loadedPatients = pacientesJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Paciente.fromJson(map);
    }).toList();

    final lembretesJson = prefs.getStringList('lembretes') ?? [];
    final loadedLembretes = lembretesJson.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return Lembrete.fromJson(map);
    }).toList();

    if (mounted) {
      setState(() {
        patients = loadedPatients;
        lembretes = loadedLembretes;
        _isLoading = false;
      });
    }
  }

  List<Lembrete> get _lembretesDoPackiente {
    if (selectedPatientId == null) return [];
    return lembretes.where((l) => l.pacienteId == selectedPatientId).toList();
  }

  Future<void> _salvarLembrete() async {
    if (selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um paciente primeiro.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um título para o lembrete.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_horarioSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um horário.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final lembrete = Lembrete(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pacienteId: selectedPatientId!,
      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      horario:
          '${_horarioSelecionado!.hour.toString().padLeft(2, '0')}:${_horarioSelecionado!.minute.toString().padLeft(2, '0')}',
      dataCriacao: DateTime.now().toIso8601String(),
    );

    final updatedLembretes = [...lembretes, lembrete];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'lembretes',
      updatedLembretes.map((l) => jsonEncode(l.toJson())).toList(),
    );

    if (mounted) {
      setState(() {
        lembretes = updatedLembretes;
        _tituloController.clear();
        _descricaoController.clear();
        _horarioSelecionado = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lembrete salvo com sucesso!'),
          backgroundColor: Color(0xFF00897B),
        ),
      );

      Navigator.pop(context);
    }
  }

  Future<void> _deletarLembrete(String id) async {
    final updatedLembretes = lembretes.where((l) => l.id != id).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'lembretes',
      updatedLembretes.map((l) => jsonEncode(l.toJson())).toList(),
    );

    setState(() {
      lembretes = updatedLembretes;
    });
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
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
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
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
                'Horário',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF00897B),
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setModalState(() => _horarioSelecionado = picked);
                    setState(() => _horarioSelecionado = picked);
                  }
                },
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
                      color: _horarioSelecionado != null
                          ? const Color(0xFF00897B)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        _horarioSelecionado != null
                            ? '${_horarioSelecionado!.hour.toString().padLeft(2, '0')}:${_horarioSelecionado!.minute.toString().padLeft(2, '0')}'
                            : 'Selecionar horário',
                        style: TextStyle(
                          fontSize: 14,
                          color: _horarioSelecionado != null
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
                  elevation: 2,
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
              // Header
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

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF00897B),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    style: TextStyle(color: Color(0xFF00897B)),
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
                                  border: Border.all(color: Colors.grey[200]!),
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
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          // ignore: deprecated_member_use
                                          color: Colors.black.withOpacity(0.05),
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
                                            color: const Color(0xFFE0F2F1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.notifications_outlined,
                                            color: Color(0xFF00897B),
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
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
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
                                                    Icons.access_time,
                                                    size: 14,
                                                    color: Color(0xFF00897B),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    lembrete.horario,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF00897B),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deletarLembrete(lembrete.id),
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
            ],
          ),
        ),
      ),
    );
  }
}
