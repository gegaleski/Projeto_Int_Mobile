import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/movement.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessKey = 'labcontrol_access_token';
  static const String _refreshKey = 'labcontrol_refresh_token';

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/token/'),
            headers: _jsonHeaders,
            body: jsonEncode({
              'username': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map ||
            data['access'] == null ||
            data['refresh'] == null) {
          throw Exception('Resposta de autenticação inválida.');
        }

        await _storage.write(
          key: _accessKey,
          value: data['access'].toString(),
        );
        await _storage.write(
          key: _refreshKey,
          value: data['refresh'].toString(),
        );
        return;
      }

      if (response.statusCode == 401 || response.statusCode == 400) {
        throw Exception('E-mail ou senha incorretos.');
      }

      throw Exception(
        'Falha ao entrar. HTTP ${response.statusCode}: ${response.body}',
      );
    } on http.ClientException {
      throw Exception(
        'Não foi possível conectar ao servidor Django.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erro inesperado durante o login: $e');
    }
  }

  static Future<void> logout() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }

  static Future<bool> restaurarSessao() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);

    if (access == null || refresh == null) return false;

    try {
      final response = await _authorizedGet('$baseUrl/equipamentos/');
      return response.statusCode == 200;
    } catch (_) {
      await logout();
      return false;
    }
  }

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Future<String?> _accessToken() {
    return _storage.read(key: _accessKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _accessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    return {
      ..._jsonHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> _refreshAccessToken() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/token/refresh/'),
            headers: _jsonHeaders,
            body: jsonEncode({'refresh': refresh}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      if (data is! Map || data['access'] == null) return false;

      await _storage.write(
        key: _accessKey,
        value: data['access'].toString(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var response = await request(await _authHeaders());

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();

      if (refreshed) {
        response = await request(await _authHeaders());
      } else {
        await logout();
        throw Exception('Sua sessão expirou. Entre novamente.');
      }
    }

    return response;
  }

  static Future<http.Response> _authorizedGet(String url) {
    return _authorizedRequest(
      (headers) => http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15)),
    );
  }

  static Future<http.Response> _authorizedPost(
    String url,
    Map<String, dynamic> body,
  ) {
    return _authorizedRequest(
      (headers) => http
          .post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15)),
    );
  }

  static Future<http.Response> _authorizedPatch(
    String url,
    Map<String, dynamic> body,
  ) {
    return _authorizedRequest(
      (headers) => http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15)),
    );
  }

  // ============================================================
  // EQUIPAMENTOS
  // ============================================================

  static Future<List<dynamic>> getEquipamentos() async {
    final response = await _authorizedGet('$baseUrl/equipamentos/');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      throw Exception('Formato inesperado na resposta dos equipamentos.');
    }

    throw Exception(
      'Erro ao buscar equipamentos: HTTP ${response.statusCode}',
    );
  }

  static Future<Map<String, dynamic>> criarEquipamento({
    required String codigoPatrimonial,
    required String nome,
    required String localizacao,
    String status = 'DISPONIVEL',
    String numeroSerie = '',
    String descricao = '',
  }) async {
    if (codigoPatrimonial.trim().isEmpty) {
      throw Exception('Informe o código patrimonial.');
    }
    if (nome.trim().isEmpty) throw Exception('Informe o nome do equipamento.');
    if (localizacao.trim().isEmpty) {
      throw Exception('Informe a localização do equipamento.');
    }

    const statusPermitidos = {
      'DISPONIVEL',
      'EM_USO',
      'EM_MANUTENCAO',
      'INATIVO',
    };
    if (!statusPermitidos.contains(status)) {
      throw Exception('Status de equipamento inválido.');
    }

    final response = await _authorizedPost(
      '$baseUrl/equipamentos/',
      {
        'codigo_patrimonial': codigoPatrimonial.trim(),
        'nome': nome.trim(),
        'localizacao': localizacao.trim(),
        'status': status,
        'numero_serie': numeroSerie.trim(),
        'descricao': descricao.trim(),
      },
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      throw Exception('Resposta inesperada ao cadastrar equipamento.');
    }

    if (response.statusCode == 400) {
      throw Exception('Dados inválidos ou código patrimonial já cadastrado: ${response.body}');
    }

    throw Exception(
      'Não foi possível cadastrar o equipamento. '
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  // ============================================================
  // MOVIMENTAÇÕES
  // ============================================================

  static Future<void> registrarMovimentacao({
    required String codigoEquipamento,
    required String tipo,
    required String origem,
    required String destino,
    required String responsavel,
    required String descricao,
    String? novoStatus,
  }) async {
    final equipamentos = await getEquipamentos();

    final equipamento = equipamentos.firstWhere(
      (item) => item['codigo_patrimonial'].toString() == codigoEquipamento,
      orElse: () => throw Exception(
        'Equipamento $codigoEquipamento não encontrado no Django.',
      ),
    );

    const tipos = {
      'Transferência': 'TRANSFERENCIA',
      'Envio para manutenção': 'ENVIO_MANUTENCAO',
      'Retorno de manutenção': 'RETORNO_MANUTENCAO',
    };

    final tipoApi = tipos[tipo];
    if (tipoApi == null) throw Exception('Tipo de movimentação inválido.');

    final body = <String, dynamic>{
      'equipamento': equipamento['id'],
      'tipo': tipoApi,
      'origem': origem,
      'destino': destino,
      'responsavel': responsavel,
      'descricao': descricao,
    };

    if (tipoApi == 'TRANSFERENCIA') {
      if (novoStatus == null || novoStatus.isEmpty) {
        throw Exception('Selecione o novo status do equipamento.');
      }
      body['novo_status'] = novoStatus;
    }

    final response = await _authorizedPost('$baseUrl/movimentacoes/', body);

    if (response.statusCode != 201) {
      throw Exception(
        'Não foi possível salvar a movimentação. '
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  static Future<List<Movement>> getMovimentacoes() async {
    final resultados = await Future.wait([
      _authorizedGet('$baseUrl/movimentacoes/'),
      getEquipamentos(),
    ]);

    final response = resultados[0] as http.Response;
    final equipamentos = resultados[1] as List<dynamic>;

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao buscar movimentações: HTTP ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is! List) {
      throw Exception('Formato inesperado na resposta das movimentações.');
    }

    final codigosPorId = <String, String>{};
    for (final equipamento in equipamentos) {
      codigosPorId[equipamento['id'].toString()] =
          equipamento['codigo_patrimonial'].toString();
    }

    const tipos = {
      'TRANSFERENCIA': 'Transferência',
      'ENVIO_MANUTENCAO': 'Envio para manutenção',
      'RETORNO_MANUTENCAO': 'Retorno de manutenção',
    };

    final movimentacoes = data.map<Movement>((item) {
      final equipamentoId = item['equipamento'].toString();
      final codigo = codigosPorId[equipamentoId];

      if (codigo == null) {
        throw Exception('Equipamento da movimentação não encontrado.');
      }

      return Movement(
        assetCode: codigo,
        type: tipos[item['tipo']] ?? item['tipo'].toString(),
        origin: item['origem']?.toString() ?? '',
        destination: item['destino']?.toString() ?? '',
        responsible: item['responsavel']?.toString() ?? '',
        description: item['descricao']?.toString() ?? '',
        date: DateTime.parse(item['data_movimentacao'].toString()).toLocal(),
      );
    }).toList();

    movimentacoes.sort((a, b) => b.date.compareTo(a.date));
    return movimentacoes;
  }

  // ============================================================
  // ORDENS DE SERVIÇO
  // ============================================================

  static Future<List<dynamic>> getOrdensServico() async {
    final response = await _authorizedGet('$baseUrl/ordens-servico/');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      throw Exception('Formato inesperado na resposta das ordens de serviço.');
    }

    throw Exception(
      'Erro ao buscar ordens de serviço: HTTP ${response.statusCode}',
    );
  }

  static Future<void> criarOrdemServico({
    required String codigoEquipamento,
    required String titulo,
    required String descricao,
    required String prioridade,
    required String responsavel,
  }) async {
    final equipamentos = await getEquipamentos();

    final equipamento = equipamentos.firstWhere(
      (item) => item['codigo_patrimonial'].toString() == codigoEquipamento,
      orElse: () => throw Exception(
        'Equipamento $codigoEquipamento não encontrado no Django.',
      ),
    );

    final response = await _authorizedPost(
      '$baseUrl/ordens-servico/',
      {
        'equipamento': equipamento['id'],
        'titulo': titulo,
        'descricao': descricao,
        'prioridade': prioridade,
        'responsavel': responsavel,
        'status': 'ABERTA',
      },
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Não foi possível criar a ordem de serviço. '
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  static Future<void> atualizarStatusOrdemServico({
    required int ordemId,
    required String status,
  }) async {
    const statusPermitidos = {
      'ABERTA',
      'EM_ANDAMENTO',
      'CONCLUIDA',
      'CANCELADA',
    };

    if (!statusPermitidos.contains(status)) {
      throw Exception('Status de ordem de serviço inválido.');
    }

    final response = await _authorizedPatch(
      '$baseUrl/ordens-servico/$ordemId/',
      {'status': status},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível atualizar a ordem de serviço. '
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }
}
