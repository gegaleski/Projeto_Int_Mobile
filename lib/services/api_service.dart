
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/movement.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ============================================================
  // EQUIPAMENTOS
  // ============================================================

  // Busca os equipamentos cadastrados no Django.
  static Future<List<dynamic>> getEquipamentos() async {
    final response = await http
        .get(Uri.parse('$baseUrl/equipamentos/'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      throw Exception(
        'Formato inesperado na resposta dos equipamentos.',
      );
    }

    throw Exception(
      'Erro ao buscar equipamentos: HTTP ${response.statusCode}',
    );
  }

  // Cadastra um equipamento no Django.
  // Este método será usado pelo cadastro manual e pelo scanner.
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

    if (nome.trim().isEmpty) {
      throw Exception('Informe o nome do equipamento.');
    }

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

    final response = await http
        .post(
          Uri.parse('$baseUrl/equipamentos/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'codigo_patrimonial': codigoPatrimonial.trim(),
            'nome': nome.trim(),
            'localizacao': localizacao.trim(),
            'status': status,
            'numero_serie': numeroSerie.trim(),
            'descricao': descricao.trim(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'O Django cadastrou o equipamento, mas retornou '
        'uma resposta em formato inesperado.',
      );
    }

    if (response.statusCode == 400) {
      final dynamic erro;

      try {
        erro = jsonDecode(response.body);
      } catch (_) {
        throw Exception(
          'Não foi possível cadastrar o equipamento: '
          '${response.body}',
        );
      }

      if (erro is Map && erro.containsKey('codigo_patrimonial')) {
        throw Exception(
          'Este código patrimonial já está cadastrado '
          'ou é inválido. Confira os dados informados.',
        );
      }

      throw Exception(
        'Dados inválidos. Confira os campos preenchidos. '
        'Detalhes: $erro',
      );
    }

    throw Exception(
      'Não foi possível cadastrar o equipamento. '
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }

  // ============================================================
  // MOVIMENTAÇÕES
  // ============================================================

  // Registra uma movimentação no banco de dados Django.
  static Future<void> registrarMovimentacao({
    required String codigoEquipamento,
    required String tipo,
    required String origem,
    required String destino,
    required String responsavel,
    required String descricao,
  }) async {
    final equipamentos = await getEquipamentos();

    final equipamento = equipamentos.firstWhere(
      (item) =>
          item['codigo_patrimonial'].toString() == codigoEquipamento,
      orElse: () => throw Exception(
        'Equipamento $codigoEquipamento não encontrado no Django.',
      ),
    );

    final tipos = {
      'Transferência': 'TRANSFERENCIA',
      'Envio para manutenção': 'ENVIO_MANUTENCAO',
      'Retorno de manutenção': 'RETORNO_MANUTENCAO',
    };

    final tipoApi = tipos[tipo];

    if (tipoApi == null) {
      throw Exception('Tipo de movimentação inválido.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/movimentacoes/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'equipamento': equipamento['id'],
            'tipo': tipoApi,
            'origem': origem,
            'destino': destino,
            'responsavel': responsavel,
            'descricao': descricao,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(
        'Não foi possível salvar a movimentação. '
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  // Busca todas as movimentações cadastradas no Django.
  static Future<List<Movement>> getMovimentacoes() async {
    final resultados = await Future.wait([
      http
          .get(Uri.parse('$baseUrl/movimentacoes/'))
          .timeout(const Duration(seconds: 15)),
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
      throw Exception(
        'Formato inesperado na resposta das movimentações.',
      );
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
        throw Exception(
          'Equipamento da movimentação não encontrado.',
        );
      }

      return Movement(
        assetCode: codigo,
        type: tipos[item['tipo']] ?? item['tipo'].toString(),
        origin: item['origem']?.toString() ?? '',
        destination: item['destino']?.toString() ?? '',
        responsible: item['responsavel']?.toString() ?? '',
        description: item['descricao']?.toString() ?? '',
        date: DateTime.parse(
          item['data_movimentacao'].toString(),
        ).toLocal(),
      );
    }).toList();

    movimentacoes.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return movimentacoes;
  }

  // ============================================================
  // ORDENS DE SERVIÇO
  // ============================================================

  // Busca as ordens de serviço cadastradas no Django.
  static Future<List<dynamic>> getOrdensServico() async {
    final response = await http
        .get(Uri.parse('$baseUrl/ordens-servico/'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      throw Exception(
        'Formato inesperado na resposta das ordens de serviço.',
      );
    }

    throw Exception(
      'Erro ao buscar ordens de serviço: HTTP ${response.statusCode}',
    );
  }

  // Cria uma ordem de serviço no Django.
  static Future<void> criarOrdemServico({
    required String codigoEquipamento,
    required String titulo,
    required String descricao,
    required String prioridade,
    required String responsavel,
  }) async {
    final equipamentos = await getEquipamentos();

    final equipamento = equipamentos.firstWhere(
      (item) =>
          item['codigo_patrimonial'].toString() == codigoEquipamento,
      orElse: () => throw Exception(
        'Equipamento $codigoEquipamento não encontrado no Django.',
      ),
    );

    final response = await http
        .post(
          Uri.parse('$baseUrl/ordens-servico/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'equipamento': equipamento['id'],
            'titulo': titulo,
            'descricao': descricao,
            'prioridade': prioridade,
            'responsavel': responsavel,
            'status': 'ABERTA',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 201) {
      throw Exception(
        'Não foi possível criar a ordem de serviço. '
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  // Atualiza o status de uma ordem de serviço existente.
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

    final response = await http
        .patch(
          Uri.parse('$baseUrl/ordens-servico/$ordemId/'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'status': status,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível atualizar a ordem de serviço. '
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }
}
