import '../models/checklist_item_model.dart';
import '../models/checklist_section_model.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late List<ChecklistSection> sections;

  @override
  void initState() {
    super.initState();
    _initializeSections();
  }

  void _initializeSections() {
    sections = [
      ChecklistSection(
        title: 'Avaliação Anterior',
        items: [
          ChecklistItem(id: 'a1', label: 'Cabeça inclinada para direita'),
          ChecklistItem(id: 'a2', label: 'Cabeça inclinada para esquerda'),
          ChecklistItem(id: 'a3', label: 'Ombro direito elevado'),
          ChecklistItem(id: 'a4', label: 'Ombro esquerdo elevado'),
          ChecklistItem(id: 'a5', label: 'Triângulo de Talles assimétrico'),
          ChecklistItem(id: 'a6', label: 'Joelhos valgos'),
          ChecklistItem(id: 'a7', label: 'Joelhos varos'),
        ],
      ),
      ChecklistSection(
        title: 'Avaliação Posterior',
        items: [
          ChecklistItem(id: 'p1', label: 'Escoliose torácica'),
          ChecklistItem(id: 'p2', label: 'Escoliose lombar'),
          ChecklistItem(id: 'p3', label: 'Escápula alada direita'),
          ChecklistItem(id: 'p4', label: 'Escápula alada esquerda'),
          ChecklistItem(id: 'p5', label: 'Crista ilíaca assimétrica'),
          ChecklistItem(id: 'p6', label: 'Pé plano direito'),
          ChecklistItem(id: 'p7', label: 'Pé plano esquerdo'),
        ],
      ),
      ChecklistSection(
        title: 'Avaliação Lateral',
        items: [
          ChecklistItem(id: 'l1', label: 'Cabeça anteriorizada'),
          ChecklistItem(id: 'l2', label: 'Hipercifose torácica'),
          ChecklistItem(id: 'l3', label: 'Hiperlordose lombar'),
          ChecklistItem(id: 'l4', label: 'Retificação lombar'),
          ChecklistItem(id: 'l5', label: 'Anteversão pélvica'),
          ChecklistItem(id: 'l6', label: 'Retroversão pélvica'),
          ChecklistItem(id: 'l7', label: 'Joelhos recurvatos'),
        ],
      ),
    ];
  }

  void _toggleItem(int sectionIndex, String itemId) {
    setState(() {
      final item = sections[sectionIndex].items.firstWhere(
        (i) => i.id == itemId,
      );
      item.checked = !item.checked;
    });
  }

  int _getTotalChecked() {
    return sections.fold(
      0,
      (total, section) =>
          total + section.items.where((item) => item.checked).length,
    );
  }

  int _getSectionCheckedCount(ChecklistSection section) {
    return section.items.where((item) => item.checked).length;
  }

  Future<void> _salvarAvaliacao() async {
    final totalChecked = _getTotalChecked();

    final prefs = await SharedPreferences.getInstance();
    final checklistData = {
      'timestamp': DateTime.now().toIso8601String(),
      'totalChecked': totalChecked,
      'sections': sections
          .map(
            (section) => {
              'title': section.title,
              'items': section.items.map((item) => item.toJson()).toList(),
            },
          )
          .toList(),
    };

    await prefs.setString('last_checklist', jsonEncode(checklistData));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checklist salvo com $totalChecked itens marcados!'),
          backgroundColor: const Color(0xFF00897B),
        ),
      );
      Navigator.pop(context);
    }
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Checklist Digital',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Avaliação postural completa',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE0F2F1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF00796B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          '${_getTotalChecked()} itens selecionados',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Checklist Sections
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  itemCount: sections.length,
                  itemBuilder: (context, sectionIndex) {
                    final section = sections[sectionIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
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
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              16,
                            ),
                            title: Text(
                              section.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    '${_getSectionCheckedCount(section)}/${section.items.length}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF00897B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            children: [
                              const SizedBox(height: 8),
                              ...section.items.map((item) {
                                return InkWell(
                                  onTap: () =>
                                      _toggleItem(sectionIndex, item.id),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: item.checked
                                          ? const Color(
                                              0xFFE0F2F1,
                                              // ignore: deprecated_member_use
                                            ).withOpacity(0.3)
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item.checked
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: item.checked
                                              ? const Color(0xFF00897B)
                                              : Colors.grey[300],
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: item.checked
                                                  ? Colors.black87
                                                  : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Botão fixo no bottom
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _salvarAvaliacao,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.save, size: 20),
                SizedBox(width: 8),
                Text(
                  'Salvar Avaliação',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
