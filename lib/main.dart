import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'widgets/rota_protegida.dart';

Future<void> main() async {
  // 1. Garante que os componentes do Flutter estão prontos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa o Supabase com as suas credenciais reais
  await Supabase.initialize(
    url: 'https://mvhalpnpybuilfjvinqh.supabase.co',
    anonKey: 'sb_publishable_FhhUpQAdDEpSFSah9aexqQ_aqtcwcQF',
  );

  // 3. Só roda o app depois que o Supabase estiver inicializado.
  // Se o usuário já tem uma sessão salva, abre direto na home; senão, no login.
  final rotaInicial = AuthService.instance.estaAutenticado ? '/home' : '/';
  runApp(ControleRemediosApp(rotaInicial: rotaInicial));
}

class ControleRemediosApp extends StatelessWidget {
  final String rotaInicial;

  const ControleRemediosApp({super.key, this.rotaInicial = '/'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Medicamentos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[150],
      ),
      initialRoute: rotaInicial,
      routes: {
        '/': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        // Tela protegida: só abre para usuários autenticados
        '/home': (context) => const RotaProtegida(child: HomeScreen()),
      },
    );
  }
}
