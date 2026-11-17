import 'package:supabase_flutter/supabase_flutter.dart';

/// Erro de autenticação com uma mensagem já pronta para ser exibida ao usuário.
class AuthServiceException implements Exception {
  final String mensagem;
  const AuthServiceException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// Serviço responsável por toda a comunicação com o Supabase Auth.
class AuthService {
  AuthService._();

  /// Instância única usada por todo o app.
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Usuário logado no momento (nulo se não houver sessão).
  User? get usuarioAtual => _client.auth.currentUser;

  /// Indica se existe uma sessão ativa.
  bool get estaAutenticado => _client.auth.currentSession != null;

  /// Emite um evento sempre que o usuário entra, sai ou a sessão expira.
  Stream<AuthState> get mudancasDeAutenticacao => _client.auth.onAuthStateChange;

  /// Nome gravado no cadastro (metadados do Auth). Se não houver, usa o e-mail.
  String get nomeUsuario {
    final usuario = usuarioAtual;
    final nome = usuario?.userMetadata?['nome']?.toString().trim();
    if (nome != null && nome.isNotEmpty) return nome;
    return usuario?.email ?? '';
  }

  /// Realiza o login com e-mail e senha.
  Future<void> entrar({required String email, required String senha}) async {
    try {
      await _client.auth.signInWithPassword(email: email.trim(), password: senha);
    } on AuthException catch (e) {
      throw AuthServiceException(_traduzirErro(e));
    } catch (_) {
      throw const AuthServiceException(
        'Não foi possível conectar. Verifique sua internet e tente novamente.',
      );
    }
  }

  /// Cadastra um novo usuário enviando o nome nos metadados (data) do Supabase Auth.
  ///
  /// Retorna 'true' se o usuário já ficou logado. Retorna 'false' quando o projeto
  /// exige confirmação de e-mail antes do primeiro login.
  Future<bool> cadastrar({
    required String nome,
    required String email,
    required String senha,
  }) async {
    try {
      final resposta = await _client.auth.signUp(
        email: email.trim(),
        password: senha,
        data: {'nome': nome.trim()},
      );

      // Com confirmação de e-mail ativa, o Supabase não gera erro para um e-mail
      // já cadastrado: ele devolve um usuário sem nenhuma identidade.
      final identidades = resposta.user?.identities;
      if (resposta.user != null && identidades != null && identidades.isEmpty) {
        throw const AuthServiceException('Este e-mail já está cadastrado.');
      }

      return resposta.session != null;
    } on AuthServiceException {
      rethrow;
    } on AuthException catch (e) {
      throw AuthServiceException(_traduzirErro(e));
    } catch (_) {
      throw const AuthServiceException(
        'Não foi possível conectar. Verifique sua internet e tente novamente.',
      );
    }
  }

  /// Encerra a sessão do usuário.
  Future<void> sair() async {
    await _client.auth.signOut();
  }

  /// Traduz os erros mais comuns do Supabase Auth para mensagens amigáveis.
  String _traduzirErro(AuthException erro) {
    final codigo = (erro.code ?? '').toLowerCase();
    final mensagem = erro.message.toLowerCase();

    if (codigo == 'invalid_credentials' || mensagem.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (codigo == 'user_already_exists' ||
        codigo == 'email_exists' ||
        mensagem.contains('already registered') ||
        mensagem.contains('already been registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (codigo == 'email_not_confirmed' || mensagem.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (codigo == 'weak_password' || mensagem.contains('password should be at least')) {
      return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
    }
    if (codigo == 'validation_failed' || mensagem.contains('unable to validate email')) {
      return 'E-mail inválido.';
    }
    if (codigo.contains('rate_limit') || mensagem.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
    }
    return 'Não foi possível concluir a operação. Tente novamente.';
  }
}
