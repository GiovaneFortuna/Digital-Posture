import 'package:digital_posture/screens/camera_screen.dart';
import 'package:digital_posture/screens/registro_de_paciente_screen.dart';
import 'package:digital_posture/screens/checklist_screen.dart';
import 'package:digital_posture/screens/whatsapp_screen.dart';
import 'package:digital_posture/screens/lembretes_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importações do seu projeto
import 'package:digital_posture/cores/app_colors.dart';
import 'package:digital_posture/screens/home_screen.dart';
import 'package:digital_posture/screens/screen_one.dart';

// Variável global para armazenar as câmeras disponíveis
List<CameraDescription> cameras = [];

Future<void> main() async {
  // Garante que os plugins inicializem antes do runApp
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Carrega as câmeras do dispositivo
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Erro ao inicializar câmeras: ${e.description}');
  }

  runApp(const DigitalPostureApp());
}

class DigitalPostureApp extends StatelessWidget {
  const DigitalPostureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Posture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        useMaterial3: true,
      ),
      home: const InitialRouteHandler(),
      routes: {
        '/auth': (context) => const ScreenOne(),
        '/home': (context) => const ProtectedRoute(child: HomeScreen()),
        '/camera': (context) => const ProtectedRoute(child: CameraScreen()),
        '/cadastro': (context) =>
            const ProtectedRoute(child: RegistroDePacienteScreen()),
        '/checklist': (context) =>
            const ProtectedRoute(child: ChecklistScreen()),
        '/whatsapp': (context) => const ProtectedRoute(child: WhatsAppScreen()),
        '/lembretes': (context) =>
            const ProtectedRoute(child: LembretesScreen()),

        // Outras rotas em desenvolvimento
        '/analise': (context) => const ProtectedRoute(
          child: PlaceholderScreen(title: 'Análise com IA'),
        ),
      },
    );
  }
}

// --- LÓGICA DE VERIFICAÇÃO DE LOGIN ---

class InitialRouteHandler extends StatefulWidget {
  const InitialRouteHandler({super.key});

  @override
  State<InitialRouteHandler> createState() => _InitialRouteHandlerState();
}

class _InitialRouteHandlerState extends State<InitialRouteHandler> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');

    if (!mounted) return;

    if (userStr != null && userStr.contains('{')) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }
}

// --- PROTEÇÃO DE ROTAS ---

class ProtectedRoute extends StatefulWidget {
  final Widget child;
  const ProtectedRoute({super.key, required this.child});

  @override
  State<ProtectedRoute> createState() => _ProtectedRouteState();
}

class _ProtectedRouteState extends State<ProtectedRoute> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');

    if (mounted) {
      setState(() {
        _isAuthenticated = userStr != null && userStr.contains('{');
        _isLoading = false;
      });

      if (!_isAuthenticated) {
        await prefs.remove('user');
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isAuthenticated ? widget.child : const SizedBox.shrink();
  }
}

// --- TELAS TEMPORÁRIAS ---
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Em desenvolvimento...',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
