import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modSchedulingEnterprise.dart';

class AgendamentoEmpresaService {
  final String baseUrl = '${ApiConfig.baseUrl}agendamento';

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Listar agendamentos dos estabelecimentos da empresa
  Future<Map<String, dynamic>> listarAgendamentosEstabelecimentos({
    required String token,
    int? estabelecimentoId,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/empresa/agendamentos';
      final queryParams = <String, String>{};

      if (estabelecimentoId != null) {
        queryParams['estabelecimentoId'] = estabelecimentoId.toString();
      }
      if (dataInicio != null) {
        queryParams['dataInicio'] = '${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}';
      }
      if (dataFim != null) {
        queryParams['dataFim'] = '${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}-${dataFim.day.toString().padLeft(2, '0')}';
      }
      if (status != null && status != 'TODOS') {
        queryParams['status'] = status;
      }

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        List<AgendamentoEmpresa> agendamentos = [];
        if (responseData['data'] != null) {
          agendamentos = (responseData['data'] as List)
              .map((item) => AgendamentoEmpresa.fromJson(item))
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

  // Buscar detalhes de um agendamento específico
  Future<Map<String, dynamic>> buscarAgendamento({
    required int agendamentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$agendamentoId'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': AgendamentoEmpresa.fromJson(responseData['data']),
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
}