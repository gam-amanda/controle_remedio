/// Modelo que representa um medicamento cadastrado na tabela 'remedios'.
class Remedio {
  /// Identificador gerado pelo banco (nulo enquanto o remédio ainda não foi salvo).
  final dynamic id;
  final String nome;
  final String dosagem;
  final List<String> horarios;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final String observacoes;
  final bool ativo;

  /// Tipo de repetição: 'Não se repete', 'Uso contínuo' ou 'Cada X horas'.
  final String tipoRepeticao;

  /// Intervalo em horas; preenchido somente quando tipoRepeticao == 'Cada X horas'.
  final double? intervaloHoras;

  const Remedio({
    this.id,
    required this.nome,
    required this.dosagem,
    required this.horarios,
    required this.dataInicio,
    this.dataFim,
    this.observacoes = '',
    this.ativo = true,
    this.tipoRepeticao = 'Não se repete',
    this.intervaloHoras,
  });

  /// Primeiro horário da lista (ou texto vazio se não houver nenhum).
  String get primeiroHorario => horarios.isNotEmpty ? horarios.first : '';

  /// Data de início no formato AAAA-MM-DD, o mesmo usado pelo banco.
  String get dataInicioTexto => _formatarDataIso(dataInicio);

  /// Constrói o modelo a partir de uma linha retornada pelo Supabase.
  factory Remedio.fromMap(Map<String, dynamic> mapa) {
    // Tratamento seguro para extrair os horários (coluna text[])
    final horariosBrutos = mapa['horarios'];
    final horarios = horariosBrutos is List
        ? horariosBrutos.map((h) => h.toString()).toList()
        : <String>[];

    final dataFimBruta = mapa['data_fim']?.toString();

    return Remedio(
      id: mapa['id'],
      nome: mapa['nome']?.toString() ?? 'Remédio',
      dosagem: mapa['dosagem']?.toString() ?? '',
      horarios: horarios,
      dataInicio: DateTime.tryParse(mapa['data_inicio']?.toString() ?? '') ?? DateTime.now(),
      dataFim: dataFimBruta == null ? null : DateTime.tryParse(dataFimBruta),
      observacoes: mapa['observacoes']?.toString() ?? '',
      ativo: mapa['ativo'] is bool ? mapa['ativo'] as bool : true,
      // Compatibilidade com registros antigos que ainda não possuem essas colunas.
      tipoRepeticao: mapa['tipo_repeticao']?.toString() ??
          (dataFimBruta == null
              ? 'Uso contínuo'
              : (_mesmoDiaIso(dataFimBruta, mapa['data_inicio']?.toString())
                  ? 'Não se repete'
                  : 'Cada X horas')),
      intervaloHoras: _lerIntervalo(mapa['intervalo_horas']),
    );
  }

  /// Converte o modelo no formato esperado pela tabela 'remedios'.
  /// O 'usuarioId' vincula o registro ao usuário autenticado (exigência do RLS).
  Map<String, dynamic> toMap(String usuarioId) {
    return {
      'usuario_id': usuarioId,
      'nome': nome,
      'dosagem': dosagem,
      'horarios': horarios,
      'data_inicio': _formatarDataIso(dataInicio),
      'data_fim': dataFim == null ? null : _formatarDataIso(dataFim!),
      'observacoes': observacoes,
      'ativo': ativo,
      'tipo_repeticao': tipoRepeticao,
      'intervalo_horas': tipoRepeticao == 'Cada X horas' ? intervaloHoras : null,
    };
  }

  static double? _lerIntervalo(dynamic valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString().replaceAll(',', '.'));
  }

  static bool _mesmoDiaIso(String? a, String? b) {
    if (a == null || b == null) return false;
    final dataA = DateTime.tryParse(a);
    final dataB = DateTime.tryParse(b);
    if (dataA == null || dataB == null) return false;
    return dataA.year == dataB.year &&
        dataA.month == dataB.month &&
        dataA.day == dataB.day;
  }

  static String _formatarDataIso(DateTime data) {
    final mes = data.month.toString().padLeft(2, '0');
    final dia = data.day.toString().padLeft(2, '0');
    return '${data.year.toString().padLeft(4, '0')}-$mes-$dia';
  }
}
