import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_repository.dart';

/// Esta é a implementação real usando SharedPreferences.
/// Ela pertence à camada de DATA (DADOS).
class AuthRepositoryImpl implements IAuthRepository {
  // Chave constante para evitar erros de digitação
  static const String _userKey = 'user';

  @override
  Future<Map<String, dynamic>?> getLoggedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);

      if (userStr != null && userStr.isNotEmpty) {
        return jsonDecode(userStr) as Map<String, dynamic>;
      }
    } catch (e) {
      // Em um TCC, é bom mostrar que você pensou em tratamento de erros
      debugPrint('Erro ao carregar usuário: $e');
    }
    return null;
  }

  @override
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Erro ao realizar logout: $e');
    }
  }

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = jsonEncode(user);
      await prefs.setString(_userKey, userStr);
    } catch (e) {
      debugPrint('Erro ao salvar usuário: $e');
    }
  }
}

// Apenas para o debugPrint funcionar se você não tiver o material importado
// ignore: avoid_print
void debugPrint(String message) => print(message);
