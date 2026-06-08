import 'dart:io';
import 'package:flutter/material.dart';

class PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;

  const PhotoPreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Preview da Foto'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ✅ Foto ocupando menos espaço para os botões ficarem mais acima
          Expanded(
            flex: 8, // ✅ 80% da tela para a foto
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Não foi possível carregar a imagem.',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // ✅ Botões com flex menor para subir na tela
          Expanded(
            flex: 2, // ✅ 20% da tela para os botões
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botão Refazer
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'Refazer',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botão Usar foto
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/analise',
                          arguments: imagePath, // ✅ Passa o caminho da foto
                        );
                      },
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Usar foto',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
