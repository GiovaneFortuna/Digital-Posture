import 'package:flutter/material.dart';
import 'package:digital_posture/cores/app_colors.dart';
import 'package:digital_posture/widgets/login_form.dart';
import 'package:digital_posture/widgets/signup_form.dart';

class ScreenOne extends StatefulWidget {
  const ScreenOne({super.key}); // Removido o Key antigo para o padrão atual

  @override
  State<ScreenOne> createState() => _ScreenOneState();
}

class _ScreenOneState extends State<ScreenOne>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Evita que o teclado empurre os widgets para cima e cause erro de layout
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header - Título e Subtítulo
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Digital Posture',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF00897B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Avaliação Postural Inteligente',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

              // Card Branco com as abas
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Tabs (Entrar / Cadastrar)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF00897B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[700],
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Entrar'),
                            Tab(text: 'Cadastrar'),
                          ],
                        ),
                      ),

                      // Conteúdo das Tabs chamando os novos Widgets
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: const [
                            LoginForm(), // Widget do arquivo widgets/login_form.dart
                            SignupForm(), // Widget do arquivo widgets/signup_form.dart
                          ],
                        ),
                      ),

                      // Rodapé de Termos
                      _buildFooter(),
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

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        'Ao continuar, você concorda com nossos Termos de Uso',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Colors.grey),
      ),
    );
  }
}
