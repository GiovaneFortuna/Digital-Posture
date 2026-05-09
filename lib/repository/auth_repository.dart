/// Esta classe define o contrato de autenticação.
/// Ela pertence à camada de DOMÍNIO.
abstract class IAuthRepository {
  /// Busca os dados do usuário salvos localmente.
  Future<Map<String, dynamic>?> getLoggedUser();

  /// Remove os dados do usuário e encerra a sessão.
  Future<void> logout();

  /// Salva os dados do usuário (útil para o seu fluxo de login futuro).
  Future<void> saveUser(Map<String, dynamic> user);
}
