import 'package:flutter_test/flutter_test.dart';
import 'package:agam_control_rem_flutter_application/models/remedio.dart';

void main() {
  group('Remedio', () {
    test('fromMap converte uma linha do banco em um Remedio', () {
      final remedio = Remedio.fromMap({
        'id': 7,
        'nome': 'Dipirona',
        'dosagem': '1 comprimido(s)',
        'horarios': ['08:00', '16:00'],
        'data_inicio': '2026-11-17',
        'data_fim': null,
        'observacoes': 'Após o almoço',
        'ativo': true,
      });

      expect(remedio.id, 7);
      expect(remedio.nome, 'Dipirona');
      expect(remedio.dosagem, '1 comprimido(s)');
      expect(remedio.horarios, ['08:00', '16:00']);
      expect(remedio.primeiroHorario, '08:00');
      expect(remedio.dataInicio, DateTime(2026, 11, 17));
      expect(remedio.dataInicioTexto, '2026-11-17');
      expect(remedio.dataFim, isNull);
      expect(remedio.observacoes, 'Após o almoço');
      expect(remedio.ativo, isTrue);
    });

    test('fromMap usa valores padrão quando faltam campos', () {
      final remedio = Remedio.fromMap({'id': 1, 'data_inicio': '2026-01-05'});

      expect(remedio.nome, 'Remédio');
      expect(remedio.dosagem, '');
      expect(remedio.horarios, isEmpty);
      expect(remedio.primeiroHorario, '');
      expect(remedio.observacoes, '');
      expect(remedio.ativo, isTrue);
    });

    test('toMap gera o formato esperado pela tabela', () {
      final remedio = Remedio(
        nome: 'Losartana',
        dosagem: '2 comprimido(s)',
        horarios: const ['07:30'],
        dataInicio: DateTime(2026, 3, 9),
        dataFim: DateTime(2026, 3, 20),
        observacoes: 'Em jejum',
      );

      final mapa = remedio.toMap('usuario-123');

      expect(mapa['usuario_id'], 'usuario-123');
      expect(mapa['nome'], 'Losartana');
      expect(mapa['dosagem'], '2 comprimido(s)');
      expect(mapa['horarios'], ['07:30']);
      expect(mapa['data_inicio'], '2026-03-09');
      expect(mapa['data_fim'], '2026-03-20');
      expect(mapa['observacoes'], 'Em jejum');
      expect(mapa['ativo'], isTrue);
      expect(mapa.containsKey('id'), isFalse);
    });

    test('toMap envia data_fim nula no uso contínuo', () {
      final remedio = Remedio(
        nome: 'Vitamina D',
        dosagem: 'gotas',
        horarios: const ['09:00'],
        dataInicio: DateTime(2026, 5, 1),
      );

      expect(remedio.toMap('usuario-123')['data_fim'], isNull);
    });
  });
}
