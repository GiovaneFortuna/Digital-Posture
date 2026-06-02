import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/menu_item_model.dart';
import '../widgets/menu_card_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _nomeProfissional;

  @override
  void initState() {
    super.initState();
    _loadProfissional();
  }

  Future<void> _loadProfissional() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) return;

      final dados = await Supabase.instance.client
          .from('profissionais')
          .select('name')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _nomeProfissional = dados['name'];
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar profissional: $e');
      }
    }
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
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
              const SizedBox(height: 16),
              Text(
                'Olá, ${_nomeProfissional ?? 'Carregando...'}! 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bem-vindo ao Digital Posture',
                style: TextStyle(color: Color(0xFFE0F2F1), fontSize: 13),
              ),
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
