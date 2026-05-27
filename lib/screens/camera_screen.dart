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
    // Pede permissão em tempo de execução
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

    // Recarrega as câmeras disponíveis
    final camerasList = await availableCameras();

    if (camerasList.isEmpty) {
      debugPrint('Nenhuma câmera encontrada.');
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
          ? Center(
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
            )
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
                    // Preview da câmera ocupando toda a tela
                    Positioned.fill(child: CameraPreview(_controller!)),

                    // Linha de prumo vertical
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
}
