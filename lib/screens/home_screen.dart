import 'package:flutter/material.dart';
import '../models/remedio.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'remedio_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista local simples para armazenar os remédios
  List<Remedio> _remedios = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarRemedios(); // Carrega ao abrir a tela
  }

  // Método simples que busca os remédios (via DatabaseService) e atualiza o estado da tela
  Future<void> _carregarRemedios() async {
    setState(() {
      _carregando = true;
    });

    try {
      final resposta = await DatabaseService.instance.listarRemedios();

      if (!mounted) return;
      setState(() {
        _remedios = resposta;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Olá, ${AuthService.instance.nomeUsuario}!',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Text(
              'Controle de Medicamentos',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () async {
              await AuthService.instance.sair();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _remedios.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum medicamento cadastrado ainda.',
                          style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Toque no botão abaixo para adicionar o seu primeiro remédio.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _remedios.length,
                  itemBuilder: (context, index) {
                    final remedio = _remedios[index];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.medication, color: Colors.white),
                        ),
                        title: Text(
                          remedio.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          'Dosagem: ${remedio.dosagem} • Horário: ${remedio.primeiroHorario}\nInício: ${remedio.dataInicioTexto}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botão de Editar
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              tooltip: 'Editar',
                              onPressed: () async {
                                // Passa o remédio para o formulário abrir em modo de edição
                                final resultado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RemedioFormScreen(remedio: remedio),
                                  ),
                                );
                                if (resultado == true) {
                                  _carregarRemedios();
                                }
                              },
                            ),
                            // Botão de Excluir
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Excluir',
                              onPressed: () async {
                                try {
                                  await DatabaseService.instance.excluirRemedio(remedio.id);
                                  _carregarRemedios(); // Atualiza a lista após excluir
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        onPressed: () async {
          // Abre o formulário e aguarda o retorno
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RemedioFormScreen(),
            ),
          );

          // Se salvou com sucesso, recarrega a lista chamando a função diretamente
          if (resultado == true) {
            _carregarRemedios();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Adicionar medicamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
