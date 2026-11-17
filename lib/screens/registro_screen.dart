import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/campo_texto.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController(); // Controlador para confirmação
  bool _cadastrando = false;

  @override
  void dispose() {
    // Libera os controladores da memória quando a tela for fechada
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  // Valida os campos e realiza o cadastro enviando o nome nos metadados do Supabase Auth
  Future<void> _cadastrar() async {
    // Validação: campos vazios, e-mail inválido, senha curta e senhas diferentes
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cadastrando = true);
    try {
      final logado = await AuthService.instance.cadastrar(
        nome: _nomeController.text,
        email: _emailController.text,
        senha: _senhaController.text,
      );

      if (!mounted) return;

      if (logado) {
        // Sucesso: vai para a home e limpa a pilha de rotas
        Navigator.pushNamedAndRemoveUntil(context, '/home', (rota) => false);
      } else {
        // O projeto exige confirmação de e-mail: volta para o login com um aviso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado! Confirme seu e-mail para entrar.'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/', (rota) => false);
      }
    } on AuthServiceException catch (e) {
      if (mounted) {
        setState(() => _cadastrando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.mensagem), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Criar Conta',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[150],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Cadastre seus dados para começar',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      CampoTexto(
                        controller: _nomeController,
                        label: 'Nome Completo',
                        icone: Icons.person,
                        textInputAction: TextInputAction.next,
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) return 'Informe seu nome.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                        textInputAction: TextInputAction.next,
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) return 'Informe a senha.';
                          if (valor.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campo de Confirmar Senha
                      CampoTexto(
                        controller: _confirmarSenhaController,
                        label: 'Confirmar Senha',
                        icone: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _cadastrar(),
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) return 'Confirme a senha.';
                          if (valor != _senhaController.text) return 'As senhas não coincidem!';
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
                        onPressed: _cadastrando ? null : _cadastrar,
                        child: _cadastrando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Cadastrar',
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
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
