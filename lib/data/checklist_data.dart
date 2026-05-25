// Importa o model para que o Dart reconheça a classe ChecklistSection
import '../models/checklist_model.dart';

List<ChecklistSection> buildInitialSections() => [
  ChecklistSection(
    title: 'Vista Anterior',
    groups: [
      ChecklistGroup(
        segment: 'Cabeça',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'a-cab-inc-d', label: 'Inclinação Direita'),
          ChecklistOption(id: 'a-cab-inc-e', label: 'Inclinação Esquerda'),
        ],
      ),
      ChecklistGroup(
        segment: 'Cabeça',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'a-cab-rot-d', label: 'Rotação Direita'),
          ChecklistOption(id: 'a-cab-rot-e', label: 'Rotação Esquerda'),
        ],
      ),
      ChecklistGroup(
        segment: 'Ombros',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'a-omb-elev', label: 'Elevados'),
          ChecklistOption(id: 'a-omb-dep', label: 'Deprimidos'),
        ],
      ),
      ChecklistGroup(
        segment: 'Ombros',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'a-omb-des-d', label: 'Desnível Direita'),
          ChecklistOption(id: 'a-omb-des-e', label: 'Desnível Esquerda'),
        ],
      ),
      ChecklistGroup(
        segment: 'Quadris',
        type: SelectionType.checkbox,
        options: [
          ChecklistOption(id: 'a-quad-d', label: 'Desnível Direita'),
          ChecklistOption(id: 'a-quad-e', label: 'Desnível Esquerda'),
        ],
      ),
      ChecklistGroup(
        segment: 'Joelhos',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'a-joe-valgo', label: 'Valgo'),
          ChecklistOption(id: 'a-joe-varo', label: 'Varo'),
        ],
      ),
      ChecklistGroup(
        segment: 'Pés',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'a-pes-norm', label: 'Normal'),
          ChecklistOption(id: 'a-pes-abd', label: 'Abduzidos'),
        ],
      ),
    ],
  ),
  ChecklistSection(
    title: 'Vista Lateral',
    groups: [
      ChecklistGroup(
        segment: 'Cervical',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'l-cerv-hiper', label: 'Hiperlordótica'),
          ChecklistOption(id: 'l-cerv-retif', label: 'Retificada'),
        ],
      ),
      ChecklistGroup(
        segment: 'Ombros',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'l-omb-prot', label: 'Protraídos'),
          ChecklistOption(id: 'l-omb-retr', label: 'Retraídos'),
        ],
      ),
      ChecklistGroup(
        segment: 'Joelhos',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'l-joe-flex', label: 'Flexos'),
          ChecklistOption(id: 'l-joe-recu', label: 'Recurvados'),
        ],
      ),
      ChecklistGroup(
        segment: 'Dorsal',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'l-dors-hiper', label: 'Hipercifótica'),
          ChecklistOption(id: 'l-dors-retif', label: 'Retificada'),
        ],
      ),
      ChecklistGroup(
        segment: 'Lombar',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'l-lomb-hiper', label: 'Hiperlordótica'),
          ChecklistOption(id: 'l-lomb-retif', label: 'Retificada'),
        ],
      ),
      ChecklistGroup(
        segment: 'Quadril',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'l-quad-ante', label: 'Anteversão'),
          ChecklistOption(id: 'l-quad-retro', label: 'Retroversão'),
        ],
      ),
      ChecklistGroup(
        segment: 'Pés',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'l-pes-cavos', label: 'Cavos'),
          ChecklistOption(id: 'l-pes-planos', label: 'Planos'),
        ],
      ),
    ],
  ),
  ChecklistSection(
    title: 'Vista Posterior',
    groups: [
      ChecklistGroup(
        segment: 'Cabeça',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'p-cab-inc-d', label: 'Inclinação Direita'),
          ChecklistOption(id: 'p-cab-inc-e', label: 'Inclinação Esquerda'),
        ],
      ),
      ChecklistGroup(
        segment: 'Ombro',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'p-omb-elev', label: 'Elevados'),
          ChecklistOption(id: 'p-omb-dep', label: 'Deprimidos'),
        ],
      ),
      ChecklistGroup(
        segment: 'Ombro',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'p-omb-des-d', label: 'Desnível Direito'),
          ChecklistOption(id: 'p-omb-des-e', label: 'Desnível Esquerda'),
        ],
      ),
      ChecklistGroup(
        segment: 'Escápula',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'p-esc-adu', label: 'ADU'),
          ChecklistOption(id: 'p-esc-alad', label: 'Alados'),
          ChecklistOption(id: 'p-esc-abd', label: 'Abduzidos'),
          ChecklistOption(id: 'p-esc-norm', label: 'Normal'),
        ],
      ),
      ChecklistGroup(
        segment: 'Quadris',
        type: SelectionType.checkbox,
        options: [
          ChecklistOption(id: 'p-quad-d', label: 'Desnível Direita'),
          ChecklistOption(id: 'p-quad-e', label: 'Desnível Esquerda'),
        ],
      ),
      ChecklistGroup(
        segment: 'Joelhos',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'p-joe-valgo', label: 'Valgo'),
          ChecklistOption(id: 'p-joe-varo', label: 'Varo'),
        ],
      ),
      ChecklistGroup(
        segment: 'Pés',
        type: SelectionType.radio,
        options: [
          ChecklistOption(id: 'p-pes-adu', label: 'Aduzidos'),
          ChecklistOption(id: 'p-pes-abd', label: 'Abduzidos'),
        ],
      ),
    ],
  ),
];
