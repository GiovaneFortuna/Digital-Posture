import 'package:flutter/material.dart';

// Importações dos arquivos criados anteriormente
import '../data/checklist_data.dart';
import '../models/checklist_model.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  static const _green = Color(0xFF00897B);
  static const _greenDark = Color(0xFF00796B);
  static const _greenLight = Color(0xFFE0F2F1);

  late List<ChecklistSection> _sections;

  @override
  void initState() {
    super.initState();
    // Consumindo a função que está lá no arquivo de data
    _sections = buildInitialSections();
  }

  int get _totalSelected =>
      _sections.fold(0, (sum, s) => sum + s.selectedCount);

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

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Checklist salvo com $_totalSelected alterações registradas!',
        ),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greenLight,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              children: _sections.map(_buildSectionCard).toList(),
            ),
          ),
          _buildBottomButton(),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _greenDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$_totalSelected alterações registradas',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card (ExpansionTile) ──────────────────────────────────────────

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

  // ── Segment grouping ──────────────────────────────────────────────────────

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

  // ── Option row (pill buttons) ─────────────────────────────────────────────

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
          onPressed: _handleSave,
          icon: const Icon(Icons.save_outlined, size: 20),
          label: const Text(
            'Salvar Avaliação',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
