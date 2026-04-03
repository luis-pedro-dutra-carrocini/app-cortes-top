import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modScheduling.dart';

class AgendamentoService {
  // Cadastrar novo agendamento
  Future<Map<String, dynamic>> cadastrarAgendamento({
    required String token,
    required int prestadorId,
    required int disponibilidadeId,
    required DateTime dataServico,
    required String horaServico,
    required List<int> servicos,
    String? observacao,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'PrestadorId': prestadorId,
          'DisponibilidadeId': disponibilidadeId,
          'AgendamentoDtServico': dataServico.toIso8601String().split('T')[0],
          'AgendamentoHoraServico': horaServico,
          'AgendamentoObservacao': observacao,
          'servicos': servicos,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Agendamento realizado com sucesso',
          'data': Agendamento.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao realizar agendamento',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Verificar disponibilidade de horário
  Future<Map<String, dynamic>> verificarDisponibilidade({
    required String token,
    required int prestadorId,
    required int disponibilidadeId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}$disponibilidadeId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData.data['DisponibilidadeStatus'] == true) {
          return {'success': true, 'disponivel': true};
        } else {
          return {'success': true, 'disponivel': false};
        }
      } else {
        return {
          'success': false,
          'message':
              responseData['error'] ?? 'Erro ao verificar disponibilidade',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar agendamentos pendentes do cliente
  Future<Map<String, dynamic>> listarMeusAgendamentosPendentes(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}/meus-cliente',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'total': responseData['total'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar agendamentos',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar todos agendamentos do cliente
  Future<Map<String, dynamic>> listarMeusAgendamentosClienteTodos({
    required String token,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? status,
  }) async {
    try {
      String url =
          '${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}/meus-agendamentos/todos';

      final queryParams = <String, String>{};
      if (dataInicio != null) {
        queryParams['dataInicio'] =
            '${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}';
      }
      if (dataFim != null) {
        queryParams['dataFim'] =
            '${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}-${dataFim.day.toString().padLeft(2, '0')}';
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'total': responseData['total'] ?? 0,
          'periodo': responseData['periodo'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar agendamentos',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Buscar agendamento por ID
  Future<Map<String, dynamic>> buscarAgendamentoPorId({
    required int agendamentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}/$agendamentoId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Agendamento.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar agendamento',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Atualizar agendamento
  Future<Map<String, dynamic>> atualizarAgendamento({
    required int agendamentoId,
    required String token,
    int? disponibilidadeId,
    DateTime? dataServico,
    String? horaServico,
    String? observacao,
    List<int>? servicos,
  }) async {
    try {
      final Map<String, dynamic> body = {};

      if (disponibilidadeId != null) {
        body['DisponibilidadeId'] = disponibilidadeId;
      }
      if (dataServico != null) {
        body['AgendamentoDtServico'] = dataServico.toIso8601String().split(
          'T',
        )[0];
      }
      if (horaServico != null) {
        body['AgendamentoHoraServico'] = horaServico;
      }
      if (observacao != null) {
        body['AgendamentoObservacao'] = observacao;
      }
      if (servicos != null) {
        body['servicos'] = servicos;
      }

      print('Enviando atualização: $body'); // Log para debug

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}/$agendamentoId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);
      print('Resposta: $responseData'); // Log para debug

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Agendamento atualizado com sucesso',
          'data': Agendamento.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao atualizar agendamento',
        };
      }
    } catch (e) {
      print('Erro: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Cancelar agendamento com motivo
  Future<Map<String, dynamic>> cancelarAgendamento({
    required int agendamentoId,
    required String token,
    String? motivo, // Novo parâmetro
  }) async {
    try {
      final Map<String, dynamic> body = {};

      if (motivo != null && motivo.isNotEmpty) {
        body['motivo'] = motivo;
      }

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}/$agendamentoId/cancelar',
        ),
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
          'message':
              responseData['message'] ?? 'Agendamento cancelado com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao cancelar agendamento',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}
