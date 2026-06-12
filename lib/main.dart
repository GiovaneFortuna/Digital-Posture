import 'package:digital_posture/screens/analise_screen.dart';
import 'package:digital_posture/screens/camera_screen.dart';
import 'package:digital_posture/screens/registro_de_paciente_screen.dart';
import 'package:digital_posture/screens/checklist_screen.dart';
import 'package:digital_posture/screens/whatsapp_screen.dart';
import 'package:digital_posture/screens/lembretes_screen.dart';
import 'package:digital_posture/screens/historico_avaliacoes_screen.dart';
import 'package:digital_posture/screens/perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:digital_posture/cores/app_colors.dart';
import 'package:digital_posture/screens/home_screen.dart';
import 'package:digital_posture/screens/screen_one.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['supabase_api_url'] ?? '',
    anonKey: dotenv.env['supabase_api_keys'] ?? '',
  );
  cameras = await availableCameras();
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
        '/whatsapp': (context) =>
            const ProtectedRoute(child: WhatsAppScreen()),
        '/lembretes': (context) =>
            ProtectedRoute(child: LembretesScreen()),
        '/historico': (context) =>
            const ProtectedRoute(child: HistoricoAvaliacoesScreen()),
        '/perfil': (context) =>
            const ProtectedRoute(child: PerfilScreen()),
        '/analise': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as String?;
          return ProtectedRoute(
            child: AnaliseScreen(imagePath: args ?? ''),
          );
        },
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
    final session = Supabase.instance.client.auth.currentSession;
    if (!mounted) return;
    if (session != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body:
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
    final session = Supabase.instance.client.auth.currentSession;
    if (mounted) {
      setState(() {
        _isAuthenticated = session != null;
        _isLoading = false;
      });
      if (!_isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    return _isAuthenticated ? widget.child : const SizedBox.shrink();
  }
}