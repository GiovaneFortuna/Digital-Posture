import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/paciente_model.dart';

class AnaliseScreen extends StatefulWidget {
  final String imagePath;
  const AnaliseScreen({super.key, required this.imagePath});
  @override
  State<AnaliseScreen> createState() => _AnaliseScreenState();
}

class _AnaliseScreenState extends State<AnaliseScreen> {
  final _supabase = Supabase.instance.client;

  bool _isAnalisando = false;
  bool _isSaving = false;
  String? _laudo;
  Map<String, double>? _angulos;

  List<Paciente> _pacientes = [];
  Paciente? _pacienteSelecionado;

  @override
  void initState() {
    super.initState();
    _loadPacientes();
  }

  Future<void> _loadPacientes() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('pacientes')
          .select()
          .eq('profissional_id', userId)
          .eq('ativo', true)
          .order('name', ascending: true);

      if (mounted) {
        setState(() {
          _pacientes = (response as List)
              .map((item) => Paciente.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao carregar pacientes: $e', Colors.red);
    }
  }

  // ── Calcula ângulo entre 3 pontos ─────────────────────────────────────────
  double _calcularAngulo(PoseLandmark a, PoseLandmark b, PoseLandmark c) {
    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    double angulo = radians * 180 / pi;
    if (angulo < 0) angulo += 360;
    if (angulo > 180) angulo = 360 - angulo;
    return angulo;
  }

  // ── Diferença de altura entre dois pontos ─────────────────────────────────
  double _diferencaAltura(PoseLandmark a, PoseLandmark b) {
    return (a.y - b.y).abs();
  }

  // ── Analisa a foto com ML Kit ─────────────────────────────────────────────
  Future<void> _analisar() async {
    if (_pacienteSelecionado == null) {
      _showSnackBar('Selecione um paciente primeiro!', Colors.red);
      return;
    }

    setState(() {
      _isAnalisando = true;
      _laudo = null;
      _angulos = null;
    });

    try {
      final inputImage = InputImage.fromFilePath(widget.imagePath);
      final poseDetector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.single),
      );

      final poses = await poseDetector.processImage(inputImage);
      await poseDetector.close();

      if (poses.isEmpty) {
        setState(() {
          _laudo =
              'Não foi possível detectar um corpo na imagem.\n\n'
              'Dicas:\n'
              '• Certifique-se que o corpo inteiro está visível\n'
              '• Use boa iluminação\n'
              '• Fundo neutro ajuda na detecção';
          _isAnalisando = false;
        });
        return;
      }

      final pose = poses.first;
      final landmarks = pose.landmarks;

      // ── Pontos do corpo ──────────────────────────────────────────
      final ombroEsq = landmarks[PoseLandmarkType.leftShoulder];
      final ombroDireito = landmarks[PoseLandmarkType.rightShoulder];
      final quadrilEsq = landmarks[PoseLandmarkType.leftHip];
      final quadrilDir = landmarks[PoseLandmarkType.rightHip];
      final joelhoEsq = landmarks[PoseLandmarkType.leftKnee];
      final joelhoDir = landmarks[PoseLandmarkType.rightKnee];
      final tornEsq = landmarks[PoseLandmarkType.leftAnkle];
      final tornDir = landmarks[PoseLandmarkType.rightAnkle];
      final orelhaEsq = landmarks[PoseLandmarkType.leftEar];
      final orelhaDir = landmarks[PoseLandmarkType.rightEar];

      if (ombroEsq == null ||
          ombroDireito == null ||
          quadrilEsq == null ||
          quadrilDir == null ||
          joelhoEsq == null ||
          joelhoDir == null ||
          tornEsq == null ||
          tornDir == null) {
        setState(() {
          _laudo =
              'Alguns pontos do corpo não foram detectados.\n'
              'Tente uma foto com o corpo inteiro bem visível.';
          _isAnalisando = false;
        });
        return;
      }

      // ── Cálculo dos ângulos ──────────────────────────────────────
      final anguloJoelhoEsq = _calcularAngulo(quadrilEsq, joelhoEsq, tornEsq);
      final anguloJoelhoDir = _calcularAngulo(quadrilDir, joelhoDir, tornDir);
      final anguloQuadrilEsq = _calcularAngulo(ombroEsq, quadrilEsq, joelhoEsq);
      final anguloQuadrilDir = _calcularAngulo(
        ombroDireito,
        quadrilDir,
        joelhoDir,
      );

      // ── Desníveis ────────────────────────────────────────────────
      final desnivelOmbros = _diferencaAltura(ombroEsq, ombroDireito);
      final desnivelQuadril = _diferencaAltura(quadrilEsq, quadrilDir);

      final angulos = {
        'Joelho Esquerdo': anguloJoelhoEsq,
        'Joelho Direito': anguloJoelhoDir,
        'Quadril Esquerdo': anguloQuadrilEsq,
        'Quadril Direito': anguloQuadrilDir,
        'Desnível Ombros (px)': desnivelOmbros,
        'Desnível Quadril (px)': desnivelQuadril,
      };

      // ── Gera o laudo textual ─────────────────────────────────────
      final laudo = _gerarLaudo(
        anguloJoelhoEsq: anguloJoelhoEsq,
        anguloJoelhoDir: anguloJoelhoDir,
        anguloQuadrilEsq: anguloQuadrilEsq,
        anguloQuadrilDir: anguloQuadrilDir,
        desnivelOmbros: desnivelOmbros,
        desnivelQuadril: desnivelQuadril,
        temOrelha: orelhaEsq != null && orelhaDir != null,
        orelhaEsq: orelhaEsq,
        orelhaDir: orelhaDir,
        ombroEsq: ombroEsq,
        ombroDireito: ombroDireito,
      );

      setState(() {
        _angulos = angulos;
        _laudo = laudo;
        _isAnalisando = false;
      });
    } catch (e) {
      setState(() {
        _laudo = 'Erro ao analisar imagem: $e';
        _isAnalisando = false;
      });
    }
  }

  // ── Gera laudo em português ───────────────────────────────────────────────
  String _gerarLaudo({
    required double anguloJoelhoEsq,
    required double anguloJoelhoDir,
    required double anguloQuadrilEsq,
    required double anguloQuadrilDir,
    required double desnivelOmbros,
    required double desnivelQuadril,
    required bool temOrelha,
    PoseLandmark? orelhaEsq,
    PoseLandmark? orelhaDir,
    required PoseLandmark ombroEsq,
    required PoseLandmark ombroDireito,
  }) {
    final buffer = StringBuffer();
    final achados = <String>[];

    buffer.writeln('LAUDO DE AVALIAÇÃO POSTURAL');
    buffer.writeln('Data: ${_formatarData(DateTime.now())}');
    buffer.writeln('Paciente: ${_pacienteSelecionado!.nomeCompleto}');
    buffer.writeln('─' * 35);
    buffer.writeln();

    // ── Cabeça e cervical ────────────────────────────────────────
    buffer.writeln('CABEÇA E CERVICAL');
    if (temOrelha && orelhaEsq != null && orelhaDir != null) {
      final desnivelOrelhas = _diferencaAltura(orelhaEsq, orelhaDir);
      if (desnivelOrelhas > 15) {
        buffer.writeln('• Inclinação lateral da cabeça detectada');
        achados.add('inclinação lateral da cabeça');
      } else {
        buffer.writeln('• Alinhamento da cabeça dentro do esperado');
      }
      // Anteriorização da cabeça
      final medOmbroX = (ombroEsq.x + ombroDireito.x) / 2;
      final medOrelhaX = (orelhaEsq.x + orelhaDir.x) / 2;
      if ((medOrelhaX - medOmbroX).abs() > 30) {
        buffer.writeln('• Anteriorização da cabeça identificada');
        achados.add('anteriorização da cabeça');
      }
    } else {
      buffer.writeln('• Pontos da cabeça não detectados na imagem');
    }
    buffer.writeln();

    // ── Ombros ───────────────────────────────────────────────────
    buffer.writeln('OMBROS');
    if (desnivelOmbros > 20) {
      final ladoElevado = ombroEsq.y < ombroDireito.y ? 'esquerdo' : 'direito';
      buffer.writeln('• Desnível de ombros: ombro $ladoElevado elevado');
      achados.add('desnível de ombros');
    } else {
      buffer.writeln('• Ombros alinhados simetricamente');
    }
    buffer.writeln();

    // ── Quadril ──────────────────────────────────────────────────
    buffer.writeln('QUADRIL');
    if (desnivelQuadril > 20) {
      buffer.writeln('• Desnível pélvico detectado');
      achados.add('desnível pélvico');
    } else {
      buffer.writeln('• Pelve alinhada horizontalmente');
    }
    buffer.writeln();

    // ── Joelhos ──────────────────────────────────────────────────
    buffer.writeln('JOELHOS');
    final diffJoelhos = (anguloJoelhoEsq - anguloJoelhoDir).abs();
    if (anguloJoelhoEsq < 160) {
      buffer.writeln(
        '• Joelho esquerdo com flexão aumentada '
        '(${anguloJoelhoEsq.toStringAsFixed(1)}°)',
      );
      achados.add('flexão de joelho esquerdo');
    }
    if (anguloJoelhoDir < 160) {
      buffer.writeln(
        '• Joelho direito com flexão aumentada '
        '(${anguloJoelhoDir.toStringAsFixed(1)}°)',
      );
      achados.add('flexão de joelho direito');
    }
    if (anguloJoelhoEsq >= 160 && anguloJoelhoDir >= 160) {
      buffer.writeln('• Extensão dos joelhos dentro do esperado');
    }
    if (diffJoelhos > 15) {
      buffer.writeln('• Assimetria entre joelhos detectada');
      achados.add('assimetria de joelhos');
    }
    buffer.writeln();

    // ── Conclusão ────────────────────────────────────────────────
    buffer.writeln('─' * 35);
    buffer.writeln('CONCLUSÃO');
    if (achados.isEmpty) {
      buffer.writeln(
        'Avaliação postural dentro dos padrões esperados. '
        'Não foram identificadas alterações significativas.',
      );
    } else {
      buffer.writeln('Foram identificadas as seguintes alterações posturais:');
      for (final achado in achados) {
        buffer.writeln('• $achado');
      }
      buffer.writeln();
      buffer.writeln(
        'Recomenda-se avaliação clínica complementar e '
        'elaboração de programa de exercícios específico.',
      );
    }

    return buffer.toString();
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  // ── Salva no Supabase ─────────────────────────────────────────────────────
  Future<void> _salvar() async {
    if (_pacienteSelecionado == null || _laudo == null) return;

    setState(() => _isSaving = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('avaliacoes').insert({
        'paciente_id': _pacienteSelecionado!.id,
        'profissional_id': userId,
        'data_avaliacao': DateTime.now().toIso8601String(),
        'status': 'concluida',
        'observacoes': _laudo,
        'conclusao_geral': _laudo!.contains('dentro dos padrões')
            ? 'Sem alterações significativas'
            : 'Alterações posturais identificadas',
      });

      if (mounted) {
        _showSnackBar('Avaliação salva com sucesso!', const Color(0xFF00897B));
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      _showSnackBar('Erro ao salvar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      backgroundColor: const Color(0xFFE0F2F1),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────
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
                    const Icon(Icons.psychology, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Análise Postural',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Detecção automática com ML Kit',
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
              ),
            ),

            // ── Conteúdo ──────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Foto
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.imagePath),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Seletor de paciente
                  _buildSeletorPaciente(),
                  const SizedBox(height: 16),

                  // Botão analisar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalisando ? null : _analisar,
                      icon: _isAnalisando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.search, color: Colors.white),
                      label: Text(
                        _isAnalisando ? 'Analisando...' : 'Analisar Postura',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ângulos detectados
                  if (_angulos != null) ...[
                    _buildCard(
                      title: 'Medições Detectadas',
                      icon: Icons.straighten,
                      child: Column(
                        children: _angulos!.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.key,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  e.key.contains('px')
                                      ? '${e.value.toStringAsFixed(1)} px'
                                      : '${e.value.toStringAsFixed(1)}°',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00897B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Laudo
                  if (_laudo != null) ...[
                    _buildCard(
                      title: 'Laudo Gerado',
                      icon: Icons.description,
                      child: Text(
                        _laudo!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botão salvar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _salvar,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Salvando...' : 'Salvar Avaliação',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeletorPaciente() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _pacienteSelecionado != null
              ? const Color(0xFF00897B)
              : Colors.grey[200]!,
          width: _pacienteSelecionado != null ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paciente',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00897B),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<Paciente>(
              isExpanded: true,
              hint: const Text('Selecione o paciente'),
              value: _pacienteSelecionado,
              items: _pacientes.map((p) {
                return DropdownMenuItem<Paciente>(
                  value: p,
                  child: Text(p.nomeCompleto),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _pacienteSelecionado = value),
            ),
          ),
        ],
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

// Helper para navegação
class NamedRoute extends Route {
  final String name;
  NamedRoute(this.name);

  @override
  bool get isCurrent => false;

  @override
  bool get isFirst => false;

  @override
  bool get hasActiveRouteBelow => false;

  @override
  bool didPop(result) {
    super.didPop(result);
    return false;
  }
}
