import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../main.dart';
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

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  void _setupCamera() {
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      _initializeControllerFuture = _controller!.initialize();
    } else {
      debugPrint('Nenhuma câmera encontrada no dispositivo.');
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

      // Navega para a tela de preview passando o caminho da foto
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
      body: cameras.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma câmera disponível',
                style: TextStyle(color: Colors.white),
              ),
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
                    // Preview da câmera ocupando toda a tela
                    Positioned.fill(child: CameraPreview(_controller!)),

                    // Linha de prumo vertical (para análise postural)
                    Center(
                      child: Container(
                        width: 1.5,
                        height: double.infinity,
                        // ignore: deprecated_member_use
                        color: Colors.red.withOpacity(0.6),
                      ),
                    ),

                    // Label da linha de prumo
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Alinhe a coluna com a linha vermelha',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

      // Botão de captura centralizado
      floatingActionButton: FloatingActionButton.large(
        onPressed: _isTakingPicture ? null : _takePicture,
        backgroundColor: const Color(0xFF00897B),
        child: _isTakingPicture
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
