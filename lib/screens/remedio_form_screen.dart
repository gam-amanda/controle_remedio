import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/remedio.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/campo_texto.dart';

/// Tela de formulário para cadastro e edição de medicamentos.
/// Se receber um [remedio], abre em modo de edição (UPDATE); senão, cria um novo (CREATE).
class RemedioFormScreen extends StatefulWidget {
  final Remedio? remedio;

  const RemedioFormScreen({super.key, this.remedio});

  @override
  State<RemedioFormScreen> createState() => _RemedioFormScreenState();
}

class _RemedioFormScreenState extends State<RemedioFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar o texto digitado nos campos do formulário
  final _nomeController = TextEditingController();
  final _dosagemQtdController = TextEditingController();
  final _horarioController = TextEditingController();
  final _intervaloHorasController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Unidade de medida padrão para a dosagem do medicamento
  String _unidadeDosagem = 'comprimido(s)';
  final List<String> _opcoesUnidades = [
    'comprimido(s)',
    'gotas',
    'ml',
    'mg',
    'cápsula(s)',
    'borrifadas',
  ];

  // Opção selecionada nos botões de rádio para definir o tipo de repetição
  String _tipoRepeticao = 'Não se repete';

  // Variáveis para controle das datas de início e término do tratamento
  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;

  // Evita cliques repetidos no botão enquanto o remédio está sendo salvo
  bool _salvando = false;

  bool get _modoEdicao => widget.remedio != null;

  @override
  void initState() {
    super.initState();
    final remedio = widget.remedio;
    if (remedio != null) {
      _preencherCampos(remedio);
    }
  }

  /// Preenche o formulário com os dados de um remédio já cadastrado (modo de edição)
  void _preencherCampos(Remedio remedio) {
    _nomeController.text = remedio.nome;
    _horarioController.text = remedio.primeiroHorario;
    _observacoesController.text = remedio.observacoes;
    _dataInicio = remedio.dataInicio;
    _dataFim = remedio.dataFim;

    // A dosagem é salva como "<qtd> <unidade>" (ex: "2 comprimido(s)"); separa de volta
    for (final unidade in _opcoesUnidades) {
      if (remedio.dosagem == unidade) {
        _unidadeDosagem = unidade;
        break;
      }
      if (remedio.dosagem.endsWith(' $unidade')) {
        _unidadeDosagem = unidade;
        _dosagemQtdController.text =
            remedio.dosagem.substring(0, remedio.dosagem.length - unidade.length - 1).trim();
        break;
      }
    }

    // Recupera exatamente as opções persistidas no banco.
    _tipoRepeticao = remedio.tipoRepeticao;
    if (remedio.intervaloHoras != null) {
      final intervalo = remedio.intervaloHoras!;
      _intervaloHorasController.text =
          intervalo == intervalo.roundToDouble()
              ? intervalo.toInt().toString()
              : intervalo.toString();
    }
  }

  bool _mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    // Libera os controladores da memória quando a tela for fechada para evitar vazamentos (memory leaks)
    _nomeController.dispose();
    _dosagemQtdController.dispose();
    _horarioController.dispose();
    _intervaloHorasController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  /// Função assíncrona para exibir o calendário e selecionar a Data de Início
  Future<void> _selecionarDataInicio() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (dataEscolhida != null) {
      setState(() {
        _dataInicio = dataEscolhida;
        // Ajusta a data fim dependendo do tipo de repetição escolhido
        if (_tipoRepeticao == 'Não se repete') {
          _dataFim = _dataInicio;
        } else if (_dataFim != null && _dataFim!.isBefore(_dataInicio)) {
          _dataFim = null;
        }
      });
    }
  }

  /// Função assíncrona para exibir o calendário e selecionar a Data de Término
  Future<void> _selecionarDataFim() async {
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? _dataInicio.add(const Duration(days: 7)),
      firstDate: _dataInicio,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (dataEscolhida != null) {
      setState(() {
        _dataFim = dataEscolhida;
      });
    }
  }

  /// Valida o formulário e salva o medicamento (cria um novo ou atualiza o existente)
  Future<void> _salvar() async {
    // 1. Validação dos campos do formulário (mostra as mensagens de erro em cada campo)
    if (!_formKey.currentState!.validate()) return;

    // 2. Validação de segurança: verifica se o usuário está logado
    if (AuthService.instance.usuarioAtual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não autenticado. Faça login novamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      // 3. Formata os dados preenchidos pelo usuário para o modelo esperado pelo banco
      final qtd = _dosagemQtdController.text.trim();
      final dosagemCompleta = qtd.isNotEmpty ? '$qtd $_unidadeDosagem' : _unidadeDosagem;

      final intervaloTexto =
          _intervaloHorasController.text.trim().replaceAll(',', '.');
      final double? intervaloHoras = _tipoRepeticao == 'Cada X horas'
          ? double.parse(intervaloTexto)
          : null;

      final remedio = Remedio(
        id: widget.remedio?.id,
        nome: _nomeController.text.trim(),
        dosagem: dosagemCompleta,
        horarios: [_horarioController.text.trim()],
        dataInicio: _dataInicio,
        dataFim: _tipoRepeticao == 'Não se repete' ? _dataInicio : null,
        observacoes: _observacoesController.text.trim(),
        ativo: widget.remedio?.ativo ?? true,
        tipoRepeticao: _tipoRepeticao,
        intervaloHoras: intervaloHoras,
      );

      // 4. Executa o INSERT (novo) ou o UPDATE (edição) na tabela 'remedios' do Supabase
      if (_modoEdicao) {
        await DatabaseService.instance.atualizarRemedio(remedio);
      } else {
        await DatabaseService.instance.criarRemedio(remedio);
      }

      // 5. Sucesso: exibe mensagem positiva e retorna para a tela anterior informando o sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_modoEdicao ? 'Medicamento atualizado com sucesso!' : 'Medicamento salvo com sucesso!'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      // 6. Tratamento de exceções e erros de comunicação/banco de dados
      if (mounted) {
        setState(() => _salvando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar medicamento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _modoEdicao ? 'Editar Medicamento' : 'Gerenciar Medicamento',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[150],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Limita a largura máxima para telas grandes (web/tablet)
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Informações do Medicamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Campo: Nome do Remédio
                      CampoTexto(
                        controller: _nomeController,
                        label: 'Nome do Remédio',
                        icone: Icons.medication,
                        validator: (valor) {
                          final nome = valor?.trim() ?? '';
                          if (nome.isEmpty) return 'Informe o nome do remédio.';
                          if (nome.length < 2) return 'O nome deve ter pelo menos 2 caracteres.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Seção de Dosagem: Quantidade numérica + Dropdown de unidade lado a lado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: CampoTexto(
                              controller: _dosagemQtdController,
                              label: 'Qtd',
                              hintText: 'Ex: 1',
                              icone: Icons.scale,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (valor) {
                                final qtd = valor?.trim() ?? '';
                                // A quantidade é opcional, mas se for preenchida precisa ser maior que zero
                                if (qtd.isNotEmpty && (int.tryParse(qtd) ?? 0) <= 0) {
                                  return 'Use um valor maior que zero.';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _unidadeDosagem,
                              decoration: const InputDecoration(
                                labelText: 'Tipo / Unidade',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: _opcoesUnidades.map((String unidade) {
                                return DropdownMenuItem<String>(
                                  value: unidade,
                                  child: Text(unidade),
                                );
                              }).toList(),
                              onChanged: (String? novaUnidade) {
                                if (novaUnidade != null) {
                                  setState(() {
                                    _unidadeDosagem = novaUnidade;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Campo: Horário Inicial com formatação automática de hora (HH:MM)
                      CampoTexto(
                        controller: _horarioController,
                        label: 'Horário Inicial',
                        hintText: '__:__',
                        icone: Icons.access_time,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _HorarioInputFormatter(),
                        ],
                        validator: _validarHorario,
                      ),
                      const SizedBox(height: 20),

                      // Rótulo da seção de repetição
                      const Text(
                        'Repetição:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),

                      // Container com opções de rádio para o tipo de repetição
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Não se repete', style: TextStyle(fontSize: 12)),
                                value: 'Não se repete',
                                groupValue: _tipoRepeticao,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: Colors.teal,
                                onChanged: (String? valor) {
                                  setState(() {
                                    _tipoRepeticao = valor!;
                                    _dataFim = _dataInicio;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('Uso contínuo', style: TextStyle(fontSize: 12)),
                                value: 'Uso contínuo',
                                groupValue: _tipoRepeticao,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: Colors.teal,
                                onChanged: (String? valor) {
                                  setState(() {
                                    _tipoRepeticao = valor!;
                                    _dataFim = null;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('A cada X horas', style: TextStyle(fontSize: 12)),
                                value: 'Cada X horas',
                                groupValue: _tipoRepeticao,
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: Colors.teal,
                                onChanged: (String? valor) {
                                  setState(() {
                                    _tipoRepeticao = valor!;
                                    _dataFim = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Campo condicional exibido apenas se a opção "Cada X horas" for selecionada
                      if (_tipoRepeticao == 'Cada X horas') ...[
                        const SizedBox(height: 16),
                        CampoTexto(
                          controller: _intervaloHorasController,
                          label: 'Intervalo em horas (ex: 8)',
                          hintText: '8',
                          suffixText: 'horas',
                          icone: Icons.timer,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                          ],
                          validator: (valor) {
                            final texto = valor?.trim().replaceAll(',', '.') ?? '';
                            if (texto.isEmpty) {
                              return 'Informe o intervalo em horas.';
                            }
                            final intervalo = double.tryParse(texto);
                            if (intervalo == null || intervalo <= 0) {
                              return 'Informe um intervalo maior que zero.';
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Seção de Datas: Início e Término lado a lado
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                side: const BorderSide(color: Colors.teal),
                                backgroundColor: Colors.white,
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              onPressed: _selecionarDataInicio,
                              icon: const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.calendar_today, color: Colors.teal, size: 18),
                              ),
                              label: Text(
                                'Início: ${_dataInicio.day.toString().padLeft(2, '0')}/${_dataInicio.month.toString().padLeft(2, '0')}/${_dataInicio.year}',
                                style: const TextStyle(color: Colors.teal, fontSize: 13),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                side: BorderSide(
                                  color: _tipoRepeticao == 'Uso contínuo' || _tipoRepeticao == 'Não se repete'
                                      ? Colors.grey
                                      : Colors.teal,
                                ),
                                backgroundColor: Colors.white,
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              onPressed: (_tipoRepeticao == 'Uso contínuo' || _tipoRepeticao == 'Não se repete')
                                  ? null
                                  : _selecionarDataFim,
                              icon: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.event_busy,
                                  color: (_tipoRepeticao == 'Uso contínuo' || _tipoRepeticao == 'Não se repete')
                                      ? Colors.grey
                                      : Colors.teal,
                                  size: 18,
                                ),
                              ),
                              label: Text(
                                _tipoRepeticao == 'Uso contínuo'
                                    ? 'Contínuo (Sem fim)'
                                    : (_tipoRepeticao == 'Não se repete'
                                        ? 'Mesmo dia'
                                        : (_dataFim == null
                                            ? 'Término (Opcional)'
                                            : 'Fim: ${_dataFim!.day.toString().padLeft(2, '0')}/${_dataFim!.month.toString().padLeft(2, '0')}/${_dataFim!.year}')),
                                style: TextStyle(
                                  color: (_tipoRepeticao == 'Uso contínuo' || _tipoRepeticao == 'Não se repete')
                                      ? Colors.grey
                                      : Colors.teal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Campo: Observações opcionais
                      CampoTexto(
                        controller: _observacoesController,
                        label: 'Observações (Opcional)',
                        hintText: 'Adicione recomendações médicas, restrições ou horários específicos...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 28),

                      // Botão para salvar o medicamento (cria ou atualiza, via DatabaseService)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _salvando ? null : _salvar,
                        child: _salvando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _modoEdicao ? 'Salvar Alterações' : 'Salvar Medicamento',
                                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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

  /// Valida o horário no formato HH:MM (horas de 00 a 23 e minutos de 00 a 59)
  String? _validarHorario(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return 'Informe o horário inicial.';

    final partes = texto.split(':');
    if (partes.length != 2 || partes[0].length != 2 || partes[1].length != 2) {
      return 'Use o formato HH:MM (ex: 08:30).';
    }

    final horas = int.tryParse(partes[0]);
    final minutos = int.tryParse(partes[1]);
    if (horas == null || minutos == null || horas > 23 || minutos > 59) {
      return 'Horário inválido.';
    }
    return null;
  }
}

/// Formatador customizado para criar a máscara de horário no formato HH:MM automaticamente
class _HorarioInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final texto = newValue.text;
    if (texto.length <= 2) {
      return newValue;
    }
    final horas = texto.substring(0, 2);
    final minutos = texto.substring(2);
    final formatado = '$horas:$minutos';

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}
