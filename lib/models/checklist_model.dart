enum SelectionType { radio, checkbox }

class ChecklistOption {
  final String id;
  final String label;
  const ChecklistOption({required this.id, required this.label});
}

class ChecklistGroup {
  final String segment;
  final SelectionType type;
  final List<ChecklistOption> options;
  String? selected;
  List<String> checked;

  ChecklistGroup({
    required this.segment,
    required this.type,
    required this.options,
    this.selected,
    List<String>? checked,
  }) : checked = checked ?? [];

  int get selectedCount {
    if (type == SelectionType.radio) return selected != null ? 1 : 0;
    return checked.length;
  }
}

class ChecklistSection {
  final String title;
  final List<ChecklistGroup> groups;
  bool isExpanded;

  ChecklistSection({
    required this.title,
    required this.groups,
    this.isExpanded = false,
  });

  int get selectedCount => groups.fold(0, (sum, g) => sum + g.selectedCount);
}
