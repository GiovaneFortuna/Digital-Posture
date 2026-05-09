import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // Certifique-se que o caminho está correto para acessar a variável 'cameras'

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  void _setupCamera() {
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio:
            false, // Desativar áudio economiza recursos e evita pedir permissão de microfone
      );

      _initializeControllerFuture = _controller!.initialize();
    } else {
      debugPrint("Nenhuma câmera encontrada no dispositivo.");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captura de Imagem'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: cameras.isEmpty
          ? const Center(child: Text("Nenhuma câmera disponível"))
          : FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: [
                      // O AspectRatio garante que o preview não fique esticado
                      Positioned.fill(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                      _buildOverlay(),
                    ],
                  );
                } else if (snapshot.hasError) {
                  // Se der erro (ex: permissão negada), avisa na tela
                  return Center(
                    child: Text("Erro na câmera: ${snapshot.error}"),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        backgroundColor: const Color(0xFF00897B),
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildOverlay() {
    return Center(
      child: Container(
        width: 2,
        height: double.infinity,
        color: Colors.red.shade300.withOpacity(0.5), // Linha de prumo para TCC
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto capturada! Salvando análise...')),
      );

      // Aqui no futuro você chamará sua IA: image.path
      debugPrint('Caminho da foto: ${image.path}');
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
    }
  }
}
