import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modAvailability.dart';

class DisponibilidadeService {
  
  // Listar disponibilidades do prestador
  Future<Map<String, dynamic>> listarMinhasDisponibilidades(
    int prestadorId,
    String token, {
    DateTime? dataInicio, // Parâmetros opcionais
    DateTime? dataFim,
  }) async {
    try {
      // Construir a URL com parâmetros de query se fornecidos
      var url =
          '${ApiConfig.baseUrl}${ApiConfig.disponibilidadeEndpoint}prestador/$prestadorId';

      // Adicionar parâmetros de query se as datas forem fornecidas
      if (dataInicio != null && dataFim != null) {
        final queryParams = <String, String>{
          'dataInicio': _formatDateForApi(dataInicio),
          'dataFim': _formatDateForApi(dataFim),
        };
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
        List<Disponibilidade> disponibilidades = [];
        List<DisponibilidadeAgrupada> agrupadoPorData = [];

        if (responseData['data'] != null) {
          disponibilidades = (responseData['data'] as List)
              .map((item) => Disponibilidade.fromJson(item))
              .toList();
        }

        // CORREÇÃO: Verificar os dois possíveis nomes (agrupadoPorData ou agrupadoPorDia)
        var agrupadoData =
            responseData['agrupadoPorData'] ?? responseData['agrupadoPorDia'];

        if (agrupadoData != null) {
          agrupadoPorData = (agrupadoData as List)
              .map((item) => DisponibilidadeAgrupada.fromJson(item))
              .toList();
        }

        print('Disponibilidades carregadas: ${disponibilidades.length}');
        print('Agrupamentos: ${agrupadoPorData.length}');
        if (dataInicio != null && dataFim != null) {
          print(
            'Período: ${_formatDateForApi(dataInicio)} até ${_formatDateForApi(dataFim)}',
          );
        }

        return {
          'success': true,
          'data': disponibilidades,
          'agrupadoPorData': agrupadoPorData,
          'agrupadoPorDia': agrupadoPorData, // Para compatibilidade
          'prestador': responseData['prestador'],
          'periodo':
              responseData['periodo'], // Informação do período consultado
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar disponibilidades',
        };
      }
    } catch (e) {
      print('Erro detalhado: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Método auxiliar para formatar data para a API
  String _formatDateForApi(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Cadastrar nova disponibilidade
  Future<Map<String, dynamic>> cadastrarDisponibilidade({
    required String token,
    required DateTime data,
    required String horaInicio,
    required String horaFim,
    int? estabelecimentoId
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.disponibilidadeEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'DisponibilidadeData': data.toIso8601String(),
          'DisponibilidadeHoraInicio': horaInicio,
          'DisponibilidadeHoraFim': horaFim,
          'EstabelecimentoId': estabelecimentoId ?? null,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Disponibilidade cadastrada com sucesso',
          'data': Disponibilidade.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['error'] ?? 'Erro ao cadastrar disponibilidade',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Atualizar disponibilidade
  Future<Map<String, dynamic>> atualizarDisponibilidade({
    required int disponibilidadeId,
    required String token,
    required DateTime data,
    required String horaInicio,
    required String horaFim,
    int? estabelecimentoId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'DisponibilidadeData': data.toIso8601String(),
        'DisponibilidadeHoraInicio': horaInicio,
        'DisponibilidadeHoraFim': horaFim,
        if (estabelecimentoId != null) 'EstabelecimentoId': estabelecimentoId,
      };

      final response = await http.put(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.disponibilidadeEndpoint}/$disponibilidadeId',
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
              responseData['message'] ??
              'Disponibilidade atualizada com sucesso',
          'data': Disponibilidade.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['error'] ?? 'Erro ao atualizar disponibilidade',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Excluir disponibilidade
  Future<Map<String, dynamic>> excluirDisponibilidade(
    int disponibilidadeId,
    String token,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.disponibilidadeEndpoint}$disponibilidadeId',
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
          'message':
              responseData['message'] ?? 'Disponibilidade excluída com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao excluir disponibilidade',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Buscar disponibilidade por ID
  Future<Map<String, dynamic>> buscarDisponibilidade(
    int disponibilidadeId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.disponibilidadeEndpoint}$disponibilidadeId',
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
          'data': Disponibilidade.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar disponibilidade',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Buscar estabelecimentos vinculados ao prestador
  Future<Map<String, dynamic>> buscarEstabelecimentosVinculados(
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}estabelecimento/prestador/vinculos/todos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar estabelecimentos',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

}
