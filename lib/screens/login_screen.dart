import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/campo_texto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _entrando = false;

  @override
  void dispose() {
    // Libera os controladores da memória quando a tela for fechada
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Valida os campos e realiza a autenticação real no Supabase Auth
  Future<void> _entrar() async {
    // Validação: campos vazios e e-mail inválido são tratados antes de chamar o Supabase
    if (!_formKey.currentState!.validate()) return;

    setState(() => _entrando = true);
    try {
      await AuthService.instance.entrar(
        email: _emailController.text,
        senha: _senhaController.text,
      );

      if (mounted) {
        // Sucesso: vai para a home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthServiceException catch (e) {
      // Tratamento de erro (credenciais incorretas, sem internet, etc.)
      if (mounted) {
        setState(() => _entrando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.mensagem), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[150], // Fundo acinzentado suave para web/desktop
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500), // Limita a largura máxima para não esticar na web
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0), // Padding interno mais confortável
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.medication, size: 64, color: Colors.teal),
                      const SizedBox(height: 16),
                      const Text(
                        'Controle de Medicamentos',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                      const SizedBox(height: 24),
                      CampoTexto(
                        controller: _emailController,
                        label: 'E-mail',
                        icone: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (valor) {
                          final email = valor?.trim() ?? '';
                          if (email.isEmpty) return 'Informe o e-mail.';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                            return 'Informe um e-mail válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CampoTexto(
                        controller: _senhaController,
                        label: 'Senha',
                        icone: Icons.lock,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _entrar(),
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) return 'Informe a senha.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _entrando ? null : _entrar,
                        child: _entrando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Entrar', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/registro');
                        },
                        child: const Text('Não tem uma conta? Cadastre-se'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
