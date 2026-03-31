import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modAvailability.dart';

class AvailabilityEmpresaService {
  final String baseUrl = '${ApiConfig.baseUrl}disponibilidade';

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Listar disponibilidades por estabelecimento
  Future<Map<String, dynamic>> listarDisponibilidadesPorEstabelecimento({
    required int estabelecimentoId,
    required String token,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      String url = '$baseUrl/estabelecimento/$estabelecimentoId';
      final queryParams = <String, String>{};

      if (dataInicio != null) {
        queryParams['dataInicio'] =
            '${dataInicio.year}-${dataInicio.month.toString().padLeft(2, '0')}-${dataInicio.day.toString().padLeft(2, '0')}';
      }
      if (dataFim != null) {
        queryParams['dataFim'] =
            '${dataFim.year}-${dataFim.month.toString().padLeft(2, '0')}-${dataFim.day.toString().padLeft(2, '0')}';
      }

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(Uri.parse(url), headers: _headers(token));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        print('Resposta da API: ${response.body}');
        List<Disponibilidade> disponibilidades = [];
        if (responseData['data'] != null) {
          disponibilidades = (responseData['data'] as List)
              .map((item) => Disponibilidade.fromJson(item))
              .toList();
        }
        return {
          'success': true,
          'data': disponibilidades,
          'agrupadoPorData': responseData['agrupadoPorData'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar disponibilidades',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar disponibilidades por prestador em um estabelecimento
  Future<Map<String, dynamic>>
  listarDisponibilidadesPrestadorPorEstabelecimento({
    required int prestadorId,
    required int estabelecimentoId,
    required String token,
    DateTime? data,
  }) async {
    try {
      String url =
          '$baseUrl/prestador/$prestadorId/estabelecimento/$estabelecimentoId';
      if (data != null) {
        url +=
            '?data=${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      }

      final response = await http.get(Uri.parse(url), headers: _headers(token));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        List<Disponibilidade> disponibilidades = [];
        if (responseData['data'] != null) {
          disponibilidades = (responseData['data'] as List)
              .map((item) => Disponibilidade.fromJson(item))
              .toList();
        }
        return {'success': true, 'data': disponibilidades};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar disponibilidades',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexión: $e'};
    }
  }
}
