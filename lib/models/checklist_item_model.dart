class ChecklistItem {
  final String id;
  final String label;
  bool checked;

  ChecklistItem({required this.id, required this.label, this.checked = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'checked': checked,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: json['id'],
    label: json['label'],
    checked: json['checked'] ?? false,
  );
}
