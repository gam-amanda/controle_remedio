import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/remedio.dart';

/// Serviço responsável pelo CRUD da tabela 'remedios' no Supabase.
class DatabaseService {
  DatabaseService._();

  /// Instância única usada por todo o app.
  static final DatabaseService instance = DatabaseService._();

  static const String _tabela = 'remedios';

  SupabaseClient get _client => Supabase.instance.client;

  /// Id do usuário autenticado. Lança um erro se não houver sessão.
  String get _usuarioId {
    final usuario = _client.auth.currentUser;
    if (usuario == null) {
      throw Exception('Usuário não autenticado. Faça login novamente.');
    }
    return usuario.id;
  }

  /// READ: lista os remédios do usuário logado, do mais novo para o mais antigo.
  Future<List<Remedio>> listarRemedios() async {
    final usuario = _client.auth.currentUser;
    if (usuario == null) return [];

    final resposta = await _client
        .from(_tabela)
        .select()
        .eq('usuario_id', usuario.id)
        .order('criado_em', ascending: false);

    return resposta.map((linha) => Remedio.fromMap(linha)).toList();
  }

  /// CREATE: insere um novo remédio vinculado ao usuário logado.
  Future<void> criarRemedio(Remedio remedio) async {
    await _client.from(_tabela).insert(remedio.toMap(_usuarioId));
  }

  /// UPDATE: atualiza um remédio existente (identificado pelo 'id').
  Future<void> atualizarRemedio(Remedio remedio) async {
    if (remedio.id == null) {
      throw Exception('Não é possível atualizar um remédio sem id.');
    }
    final usuarioId = _usuarioId;
    await _client
        .from(_tabela)
        .update(remedio.toMap(usuarioId))
        .eq('id', remedio.id)
        .eq('usuario_id', usuarioId);
  }

  /// DELETE: remove um remédio pelo 'id'.
  Future<void> excluirRemedio(dynamic id) async {
    await _client.from(_tabela).delete().eq('id', id).eq('usuario_id', _usuarioId);
  }
}
