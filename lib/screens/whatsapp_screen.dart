import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Modificado: Usando o pacote oficial estável
import '../models/paciente_model.dart';
import '../models/mensagem_rapida.dart';
import '../constants/mensagens_whatsapp.dart';

class WhatsAppScreen extends StatefulWidget {
  const WhatsAppScreen({super.key});

  @override
  State<WhatsAppScreen> createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen> {
  final _supabase = Supabase.instance.client;
  String? selectedPatientId;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _buscaController = TextEditingController();

  List<Paciente> patients = [];
  List<Paciente> patientsFiltrados = [];
  bool _isLoading = true;

  final List<MensagemRapida> quickMessages = [
    MensagemRapida(
      title: 'Agendar Consulta',
      icon: Icons.calendar_today,
      message: MensagensWhatsApp.agendarConsulta,
      color: Colors.green,
    ),
    MensagemRapida(
      title: 'Enviar Resultado',
      icon: Icons.description,
      message: MensagensWhatsApp.enviarResultado,
      color: Colors.blue,
    ),
    MensagemRapida(
      title: 'Lembrete de Exercícios',
      icon: Icons.access_time,
      message: MensagensWhatsApp.lembreteExercicios,
      color: Colors.purple,
    ),
    MensagemRapida(
      title: 'Feedback Pós-Sessão',
      icon: Icons.chat_bubble_outline,
      message: MensagensWhatsApp.feedbackPosSessao,
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _buscaController.addListener(_filtrarPacientes);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('pacientes')
          .select()
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          patients = (response as List)
              .map((item) => Paciente.fromJson(item))
              .toList();
          patientsFiltrados = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao carregar pacientes: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _filtrarPacientes() {
    final busca = _buscaController.text.toLowerCase();
    setState(() {
      patientsFiltrados = patients
          .where((p) => p.nomeCompleto.toLowerCase().contains(busca))
          .toList();
    });
  }

  Future<void> _deletePatient(String patientId, String name) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remover Paciente'),
        content: Text(
          'Deseja remover "$name" da lista?\n\nOs dados serão mantidos no banco.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _supabase.from('pacientes').delete().eq('id', patientId);

      if (selectedPatientId == patientId) {
        setState(() => selectedPatientId = null);
      }

      _showSnackBar('Paciente removido da lista!', const Color(0xFF00897B));
      _loadPatients();
    } catch (e) {
      _showSnackBar('Erro ao remover paciente: $e', Colors.red);
    }
  }

  Future<void> _editPatient(Paciente paciente) async {
    final nomeController = TextEditingController(text: paciente.nomeCompleto);
    final telefoneController = TextEditingController(text: paciente.telefone);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Paciente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: telefoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supabase
                    .from('pacientes')
                    .update({
                      'name': nomeController.text.trim(),
                      'telefone': telefoneController.text.trim(),
                    })
                    .eq('id', paciente.id!);

                if (context.mounted) Navigator.pop(context);
                _showSnackBar('Paciente updated!', const Color(0xFF00897B));
                _loadPatients();
              } catch (e) {
                _showSnackBar('Erro ao editar: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
            ),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Método de envio totalmente reformulado usando url_launcher universal
  Future<void> _sendMessage(String message) async {
    if (selectedPatientId == null) {
      _showSnackBar('Selecione um paciente primeiro!', Colors.red);
      return;
    }

    final patient = patients.firstWhere((p) => p.id == selectedPatientId);
    final telefone = patient.telefone ?? '';
    final nome = patient.nomeCompleto.split(' ').first;

    if (telefone.isEmpty) {
      _showSnackBar('Este paciente não tem telefone cadastrado!', Colors.red);
      return;
    }

    final mensagemFinal = message.replaceAll('{nome}', nome);

    // Trata o número limpando caracteres e inserindo o DDI do Brasil (55)
    String phoneNumber = telefone.replaceAll(RegExp(r'\D'), '');
    if (!phoneNumber.startsWith('55')) {
      phoneNumber = '55$phoneNumber';
    }

    // Codifica a mensagem para o formato seguro de URL (converte espaços e acentos)
    final urlEncodedMessage = Uri.encodeComponent(mensagemFinal);

    // Constrói a URI universal do WhatsApp (funciona em Android, iOS e Web)
    final whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber?text=$urlEncodedMessage',
    );

    try {
      // Tenta abrir o aplicativo nativo ou o navegador
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode
              .externalApplication, // ✅ Força abrir fora do app (direto no WhatsApp)
        );
      } else {
        _showSnackBar('Não foi possível abrir o WhatsApp.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erro ao abrir o aplicativo: $e', Colors.red);
    }
  }

  void _showSnackBar(String text, Color background) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: background));
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
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF00897B), Color(0xFF00796B)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chat, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Atalhos WhatsApp',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Comunicação rápida com pacientes',
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _buscaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar paciente...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
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
                        onRefresh: _loadPatients,
                        color: const Color(0xFF00897B),
                        child: ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            // ── Selecionar Paciente ──────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Selecionar Paciente',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    await Navigator.pushNamed(
                                      context,
                                      '/cadastro',
                                    );
                                    _loadPatients();
                                  },
                                  icon: const Icon(
                                    Icons.add,
                                    size: 18,
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

                            if (patientsFiltrados.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: const Text(
                                  'Nenhum paciente encontrado.',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ...patientsFiltrados.map((patient) {
                                final isSelected =
                                    selectedPatientId == patient.id;
                                final inicial = patient.nomeCompleto.isNotEmpty
                                    ? patient.nomeCompleto[0].toUpperCase()
                                    : 'P';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
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
                                    child: ListTile(
                                      onTap: () => setState(
                                        () => selectedPatientId = patient.id,
                                      ),
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: isSelected
                                            ? const Color(0xFF00897B)
                                            : Colors.grey[400],
                                        child: Text(
                                          inicial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        patient.nomeCompleto,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        patient.telefone ?? 'Sem telefone',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF00897B),
                                              size: 22,
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Color(0xFF00897B),
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _editPatient(patient),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red[400],
                                              size: 20,
                                            ),
                                            onPressed: () => _deletePatient(
                                              patient.id!,
                                              patient.nomeCompleto,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),

                            const SizedBox(height: 24),

                            // ── Mensagens Rápidas ────────────────
                            const Text(
                              'Mensagens Rápidas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.3,
                                  ),
                              itemCount: quickMessages.length,
                              itemBuilder: (context, index) {
                                final template = quickMessages[index];
                                return InkWell(
                                  onTap: () => _sendMessage(template.message),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: template.color,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Icon(
                                            template.icon,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          template.title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // ── Mensagem Personalizada ───────────
                            const Text(
                              'Mensagem Personalizada',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[100]!),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _messageController,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      hintText: 'Digite sua mensagem aqui...',
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF00897B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        if (_messageController.text
                                            .trim()
                                            .isNotEmpty) {
                                          _sendMessage(
                                            _messageController.text.trim(),
                                          );
                                          _messageController.clear();
                                        }
                                      },
                                      icon: const Icon(Icons.send, size: 18),
                                      label: const Text(
                                        'Enviar Mensagem',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF00897B,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
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
