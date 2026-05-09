import 'package:flutter/material.dart';
import '../repository/auth_repository_implement.dart';
import '../repository/auth_repository.dart';
import '../models/menu_item_model.dart';
import '../widgets/menu_card_widget.dart';

class HomeScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Instância do repositório seguindo Clean Architecture
  final IAuthRepository _authRepository = AuthRepositoryImpl();

  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // Lógica agora utiliza o repositório, sem conhecer SharedPreferences
  Future<void> _loadUser() async {
    final userData = await _authRepository.getLoggedUser();
    if (userData != null) {
      setState(() {
        user = userData;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authRepository.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      MenuItemModel(
        title: 'Novo Paciente',
        description: 'Cadastrar prontuário',
        icon: Icons.person_add_outlined,
        route: '/cadastro',
        color: const Color(0xFF00897B),
      ),
      MenuItemModel(
        title: 'Checklist Digital',
        description: 'Avaliação postural',
        icon: Icons.checklist_outlined,
        route: '/checklist',
        color: const Color(0xFF00796B),
      ),
      MenuItemModel(
        title: 'Captura de Imagem',
        description: 'Protocolo fotográfico',
        icon: Icons.camera_alt_outlined,
        route: '/camera',
        color: const Color(0xFF00897B),
      ),
      MenuItemModel(
        title: 'Análise com IA',
        description: 'Detecção automática',
        icon: Icons.psychology_outlined,
        route: '/analise',
        color: const Color(0xFF00796B),
      ),
      MenuItemModel(
        title: 'Lembretes',
        description: 'Notificações educativas',
        icon: Icons.notifications_outlined,
        route: '/lembretes',
        color: const Color(0xFF00897B),
      ),
      MenuItemModel(
        title: 'WhatsApp',
        description: 'Atalhos rápidos',
        icon: Icons.chat_bubble_outline,
        route: '/whatsapp',
        color: const Color(0xFF00796B),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2F1), Colors.white],
          ),
        ),
        child: Column(children: [_buildHeader(), _buildMenuGrid(menuItems)]),
      ),
    );
  }

  // --- MÉTODOS AUXILIARES DE UI ---

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF00897B),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Digital Posture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _handleLogout,
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      // ignore: deprecated_member_use
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
              if (user != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Olá, ${user!['name'] ?? 'Usuário'}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid(List<MenuItemModel> items) {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => MenuCardWidget(item: items[index]),
      ),
    );
  }
}
