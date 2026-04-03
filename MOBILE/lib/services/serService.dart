import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modService.dart';

class ServicoService {
  // Listar serviços do prestador logado
  Future<Map<String, dynamic>> listarMeusServicos(int prestadorId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicoEndpoint}prestador/$prestadorId/todos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        List<Servico> servicos = [];
        if (responseData['data'] != null) {
          servicos = (responseData['data'] as List)
              .map((item) => Servico.fromJson(item))
              .toList();
        }
        
        return {
          'success': true,
          'data': servicos,
          'prestador': responseData['prestador'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar serviços',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // Cadastrar novo serviço
  Future<Map<String, dynamic>> cadastrarServico({
    required String token,
    required String nome,
    String? descricao,
    required int tempoMedio,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicoEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'ServicoNome': nome.trim(),
          'ServicoDescricao': descricao?.trim(),
          'ServicoTempoMedio': tempoMedio,
          'ServicoAtivo': true,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Serviço cadastrado com sucesso',
          'data': Servico.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao cadastrar serviço',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // Buscar serviço por ID
  Future<Map<String, dynamic>> buscarServico(int servicoId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicoEndpoint}$servicoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Servico.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar serviço',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // Atualizar serviço
  Future<Map<String, dynamic>> atualizarServico({
    required int servicoId,
    required String token,
    String? nome,
    String? descricao,
    int? tempoMedio,
    bool? ativo,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      
      if (nome != null) body['ServicoNome'] = nome.trim();
      if (descricao != null) body['ServicoDescricao'] = descricao.trim();
      if (tempoMedio != null) body['ServicoTempoMedio'] = tempoMedio;
      if (ativo != null) body['ServicoAtivo'] = ativo;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicoEndpoint}$servicoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Serviço atualizado com sucesso',
          'data': Servico.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao atualizar serviço',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // Alternar status do serviço (ativar/desativar)
  Future<Map<String, dynamic>> alternarStatusServico({
    required int servicoId,
    required String token,
    required bool ativo,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicoEndpoint}$servicoId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'ativo': ativo}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 
              'Serviço ${ativo ? 'ativado' : 'desativado'} com sucesso',
          'data': Servico.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao alterar status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // Excluir serviço
  Future<Map<String, dynamic>> excluirServico(int servicoId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicoEndpoint}$servicoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Serviço excluído com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao excluir serviço',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // Adicionar novo preço ao serviço
  Future<Map<String, dynamic>> adicionarPreco({
    required int servicoId,
    required String token,
    required double valor,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicoPrecoEndpoint}servico/$servicoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'ServicoValor': valor}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Preço adicionado com sucesso',
          'data': PrecoServico.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao adicionar preço',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // Listar histórico de preços do serviço
  Future<Map<String, dynamic>> listarHistoricoPrecos({
    required int servicoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicoPrecoEndpoint}servico/$servicoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        List<PrecoServico> precos = [];
        if (responseData['data'] != null) {
          precos = (responseData['data'] as List)
              .map((item) => PrecoServico.fromJson(item))
              .toList();
        }
        
        return {
          'success': true,
          'data': precos,
          'servico': responseData['servico'],
          'estatisticas': responseData['estatisticas'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar histórico de preços',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // Buscar preço atual do serviço
  Future<Map<String, dynamic>> buscarPrecoAtual(int servicoId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.servicoEndpoint}$servicoId/preco-atual'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar preço atual',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }
}