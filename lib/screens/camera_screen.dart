import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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

  @override
  void initState() {
    super.initState();
    _setupCamera();
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
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;

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

                    // ── Grade do posturógrafo ──────────────
                    CustomPaint(painter: _GradePainter()),
                  ],
                );
              },
            ),

      floatingActionButton:
          _permissaoNegada || _initializeControllerFuture == null
          ? null
          : FloatingActionButton.large(
              onPressed: _isTakingPicture ? null : _takePicture,
              backgroundColor: const Color(0xFF00897B),
              child: _isTakingPicture
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

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

// ── Painter da grade do posturógrafo ─────────────────────────────────────────

class _GradePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grade de fundo (quadrículas de 40px)
    final paintGrade = Paint()
      // ignore: deprecated_member_use
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 0.6;

    for (double x = 0; x <= w; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), paintGrade);
    }
    for (double y = 0; y <= h; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(w, y), paintGrade);
    }

    // Linha vertical central
    final paintCentral = Paint()
      // ignore: deprecated_member_use
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 1.2;

    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), paintCentral);

    // Linha horizontal central
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), paintCentral);
  }

  @override
  bool shouldRepaint(_GradePainter old) => false;
}
