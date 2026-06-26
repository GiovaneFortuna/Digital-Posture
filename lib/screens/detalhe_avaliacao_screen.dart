import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetalheAvaliacaoScreen extends StatefulWidget {
  final Map<String, dynamic> avaliacao;
  final String nomePaciente;

  const DetalheAvaliacaoScreen({
    super.key,
    required this.avaliacao,
    required this.nomePaciente,
  });

  @override
  State<DetalheAvaliacaoScreen> createState() =>
      _DetalheAvaliacaoScreenState();
}

class _DetalheAvaliacaoScreenState extends State<DetalheAvaliacaoScreen> {
  final _supabase = Supabase.instance.client;

  String? _fotoUrlAssinada;
  bool _isLoadingFoto = true;

  @override
  void initState() {
    super.initState();
    _carregarFoto();
  }

  // ✅ Gera uma URL temporária e segura para exibir a foto do bucket privado
  Future<void> _carregarFoto() async {
    final path = widget.avaliacao['foto_url']?.toString();

    if (path == null || path.isEmpty) {
      setState(() => _isLoadingFoto = false);
      return;
    }

    try {
      final url = await _supabase.storage
          .from('fotos-pacientes')
          .createSignedUrl(path, 3600); // expira em 1 hora

      if (mounted) {
        setState(() {
          _fotoUrlAssinada = url;
          _isLoadingFoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFoto = false);
      }
    }
  }

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
    final temAlteracoes = widget.avaliacao['conclusao_geral']
            ?.toString()
            .contains('Alterações') ??
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
                              widget.nomePaciente,
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
                    // ✅ Foto carregada do Storage privado via URL assinada
                    _buildFoto(),
                    const SizedBox(height: 16),

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
                                  widget.avaliacao['conclusao_geral']
                                          ?.toString() ??
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
                                  _formatarData(
                                    widget.avaliacao['data_avaliacao'],
                                  ),
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
                        widget.avaliacao['observacoes']?.toString() ??
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

  // ✅ Widget que carrega a foto do Storage privado
  Widget _buildFoto() {
    if (_isLoadingFoto) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00897B)),
        ),
      );
    }

    if (_fotoUrlAssinada == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined,
                  size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Foto não disponível',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _fotoUrlAssinada!,
          height: 350,
          width: double.infinity,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 350,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: Color(0xFF00897B),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined,
                      size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Erro ao carregar foto',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          },
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