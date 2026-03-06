import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modSchedulingAttendant.dart';

class AgendamentoPrestadorService {
  // Listar agendamentos do prestador com filtro opcional de data
  Future<Map<String, dynamic>> listarMeusAgendamentos({
    required String token,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      String url =
          '${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}/meus-prestador';

      // Adicionar query parameters se fornecidos
      if (dataInicio != null || dataFim != null) {
        url += '?';
        if (dataInicio != null) {
          url +=
              'dataInicio=${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}';
        }
        if (dataFim != null) {
          if (dataInicio != null) url += '&';
          url +=
              'dataFim=${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}-${dataFim.day.toString().padLeft(2, '0')}';
        }
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
        List<AgendamentoPrestador> agendamentos = [];
        if (responseData['data'] != null) {
          agendamentos = (responseData['data'] as List)
              .map((item) => AgendamentoPrestador.fromJson(item))
              .toList();
        }
        return {
          'success': true,
          'data': agendamentos,
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

  // Atualizar status do agendamento
  Future<Map<String, dynamic>> atualizarStatus({
    required int agendamentoId,
    required String token,
    required String status,
    String? descricaoTrabalho,
  }) async {
    try {
      final Map<String, dynamic> body = {'AgendamentoStatus': status};

      if (descricaoTrabalho != null) {
        body['AgendamentoDescricaoTrabalho'] = descricaoTrabalho;
      }

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}/$agendamentoId/status',
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
          'message': responseData['message'] ?? 'Status atualizado com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao atualizar status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> confirmarAgendamento({
    required int agendamentoId,
    required String token,
  }) async {
    return await atualizarStatus(
      agendamentoId: agendamentoId,
      token: token,
      status: 'CONFIRMADO',
    );
  }

  // Cancelar agendamento
  Future<Map<String, dynamic>> cancelarAgendamento({
    required int agendamentoId,
    required String token,
    String? motivo, // Novo parâmetro opcional
  }) async {
    try {
      final Map<String, dynamic> body = {};

      if (motivo != null && motivo.isNotEmpty) {
        body['motivo'] = motivo;
      }

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.agendamentoEndpoint}$agendamentoId/cancelar',
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
              responseData['message'] ?? 'Operação realizada com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao realizar operação',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}
