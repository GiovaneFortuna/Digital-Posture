import 'package:flutter/material.dart';

class DetalheAvaliacaoScreen extends StatelessWidget {
  final Map<String, dynamic> avaliacao;
  final String nomePaciente;

  const DetalheAvaliacaoScreen({
    super.key,
    required this.avaliacao,
    required this.nomePaciente,
  });

  String _formatarData(String? dataStr) {
    if (dataStr == null) return 'Data desconhecida';
    final data = DateTime.tryParse(dataStr);
    if (data == null) return 'Data inválida';
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} às '
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final temAlteracoes =
        avaliacao['conclusao_geral']?.toString().contains('Alterações') ??
        false;

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
              // ── Header ────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF00796B)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
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
                        Icons.description,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalhe da Avaliação',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              nomePaciente,
                              style: const TextStyle(
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

              // ── Conteúdo ──────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Card de status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: temAlteracoes
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: temAlteracoes
                              ? Colors.red[200]!
                              : const Color(0xFF00897B),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            temAlteracoes
                                ? Icons.warning_outlined
                                : Icons.check_circle_outline,
                            color: temAlteracoes
                                ? Colors.red[400]
                                : const Color(0xFF00897B),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  avaliacao['conclusao_geral']?.toString() ??
                                      'Avaliação',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: temAlteracoes
                                        ? Colors.red[700]
                                        : const Color(0xFF00897B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatarData(avaliacao['data_avaliacao']),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card do laudo
                    _buildCard(
                      title: 'Laudo Completo',
                      icon: Icons.article_outlined,
                      child: Text(
                        avaliacao['observacoes']?.toString() ??
                            'Sem observações',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00897B), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
