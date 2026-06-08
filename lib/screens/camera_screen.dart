import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'photo_preview_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isTakingPicture = false;
  bool _permissaoNegada = false;

  // ✅ Nível do celular
  double _inclinacaoX = 0; // Inclinação lateral (rolagem)
  double _inclinacaoY = 0; // Inclinação frente/trás
  StreamSubscription? _sensorSubscription;

  // Tolerância em graus para considerar nivelado
  static const double _tolerancia = 5.0;

  bool get _nivelado =>
      _inclinacaoX.abs() < _tolerancia && _inclinacaoY.abs() < _tolerancia;

  @override
  void initState() {
    super.initState();
    _setupCamera();
    _setupSensor();
  }

  void _setupSensor() {
    _sensorSubscription = accelerometerEventStream().listen((event) {
      if (mounted) {
        setState(() {
          // Converte aceleração para graus aproximados
          _inclinacaoX = event.x * 5; // Lateral
          _inclinacaoY = event.y * 5; // Frente/trás (ideal = 9.8)
        });
      }
    });
  }

  Future<void> _setupCamera() async {
    final status = await Permission.camera.request();

    if (!status.isGranted) {
      if (mounted) {
        setState(() => _permissaoNegada = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de câmera negada!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final camerasList = await availableCameras();

    if (camerasList.isEmpty) {
      if (mounted) setState(() => _permissaoNegada = true);
      return;
    }

    _controller = CameraController(
      camerasList[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    if (mounted) {
      setState(() {
        _initializeControllerFuture = _controller!.initialize();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;

    if (!_nivelado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nivele o celular antes de tirar a foto!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      setState(() => _isTakingPicture = true);
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoPreviewScreen(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Captura de Imagem'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: _permissaoNegada
          ? _buildPermissaoNegada()
          : _initializeControllerFuture == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00897B)),
            )
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro na câmera:\n${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00897B)),
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Preview da câmera ──────────────────
                    Positioned.fill(child: CameraPreview(_controller!)),

                    // ── Grade de referência ────────────────
                    CustomPaint(painter: _GradePainter(nivelado: _nivelado)),

                    // ── Indicador de nível no topo ─────────
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: _buildIndicadorNivel(),
                    ),

                    // ── Instrução na base ──────────────────
                    Positioned(
                      bottom: 100,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _nivelado
                                ? '✅ Celular nivelado! Pode fotografar.'
                                : '⚠️ Ajuste o celular até nivelar',
                            style: TextStyle(
                              color: _nivelado
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

      floatingActionButton:
          _permissaoNegada || _initializeControllerFuture == null
          ? null
          : FloatingActionButton.large(
              onPressed: _isTakingPicture ? null : _takePicture,
              backgroundColor: _nivelado
                  ? const Color(0xFF00897B)
                  : Colors.orange, // ✅ Laranja quando não nivelado
              child: _isTakingPicture
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── Indicador de nível ────────────────────────────────────────────────────

  Widget _buildIndicadorNivel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Indicador lateral
              _buildBarraInclinacao(
                label: 'Lateral',
                valor: _inclinacaoX,
                icone: Icons.swap_horiz,
              ),
              // Bolha central de nível
              _buildBolhaNivel(),
              // Indicador frente/trás
              _buildBarraInclinacao(
                label: 'Vertical',
                valor: _inclinacaoY,
                icone: Icons.swap_vert,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBarraInclinacao({
    required String label,
    required double valor,
    required IconData icone,
  }) {
    final nivelado = valor.abs() < _tolerancia;
    return Column(
      children: [
        Icon(
          icone,
          color: nivelado ? Colors.greenAccent : Colors.orangeAccent,
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        Text(
          '${valor.toStringAsFixed(1)}°',
          style: TextStyle(
            color: nivelado ? Colors.greenAccent : Colors.orangeAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBolhaNivel() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _nivelado ? Colors.greenAccent : Colors.orangeAccent,
          width: 2,
        ),
        color: Colors.black26,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cruz central
          Container(width: 1, height: 60, color: Colors.white24),
          Container(width: 60, height: 1, color: Colors.white24),
          // Bolha
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: 30 + _inclinacaoX.clamp(-20.0, 20.0) - 8,
            top: 30 - _inclinacaoY.clamp(-20.0, 20.0) - 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _nivelado ? Colors.greenAccent : Colors.orangeAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Permissão negada ──────────────────────────────────────────────────────

  Widget _buildPermissaoNegada() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Permissão de câmera necessária',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vá em Configurações e permita o acesso à câmera',
            style: TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _permissaoNegada = false);
              _setupCamera();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar novamente'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text(
              'Abrir configurações',
              style: TextStyle(color: Color(0xFF00897B)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter da grade ──────────────────────────────────────────────────────────

class _GradePainter extends CustomPainter {
  final bool nivelado;

  _GradePainter({required this.nivelado});

  @override
  void paint(Canvas canvas, Size size) {
    final color = nivelado
        // ignore: deprecated_member_use
        ? Colors.green.withOpacity(0.5)
        // ignore: deprecated_member_use
        : Colors.red.withOpacity(0.5);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    // Linha vertical central
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Linha horizontal central
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Linhas verticais auxiliares (1/3 e 2/3)
    final paintAux = Paint()
      // ignore: deprecated_member_use
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paintAux,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paintAux,
    );

    // Linhas horizontais auxiliares (1/3 e 2/3)
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paintAux,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paintAux,
    );

    // Círculo central de referência
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      40,
      Paint()
        // ignore: deprecated_member_use
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_GradePainter oldDelegate) =>
      oldDelegate.nivelado != nivelado;
}
