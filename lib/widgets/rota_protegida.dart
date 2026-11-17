import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Protege uma tela: só mostra o conteúdo se houver um usuário autenticado.
/// Sem sessão (ou se ela expirar enquanto a tela está aberta), volta para o login.
class RotaProtegida extends StatelessWidget {
  final Widget child;

  const RotaProtegida({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.instance.mudancasDeAutenticacao,
      builder: (context, snapshot) {
        if (AuthService.instance.estaAutenticado) {
          return child;
        }

        // Sem sessão: redireciona para o login depois que o frame terminar de ser desenhado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Só redireciona se esta ainda for a tela visível (evita navegar duas vezes ao sair)
          if (context.mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (rota) => false);
          }
        });

        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.teal)),
        );
      },
    );
  }
}
