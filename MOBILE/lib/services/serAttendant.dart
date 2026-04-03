import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modAttendant.dart';
import '../models/modService.dart';
import '../models/modAvailability.dart';

class PrestadorService {
  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Buscar últimos 5 prestadores
  Future<Map<String, dynamic>> buscarUltimosPrestadores(String token) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}prestadores/ultimos',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        List<Prestador> prestadores = [];
        if (responseData['data'] != null) {
          prestadores = (responseData['data'] as List)
              .map((item) => Prestador.fromJson(item))
              .toList();
        }
        return {'success': true, 'data': prestadores};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar prestadores',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Pesquisar prestadores por nome ou telefone
  Future<Map<String, dynamic>> pesquisarPrestadores({
    required String token,
    String? nome,
    String? telefone,
  }) async {
    try {
      String url =
          '${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}prestadores/pesquisa?';
      if (nome != null && nome.isNotEmpty) {
        url += 'nome=$nome';
      } else if (telefone != null && telefone.isNotEmpty) {
        url += 'telefone=$telefone';
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
        List<Prestador> prestadores = [];
        if (responseData['data'] != null) {
          prestadores = (responseData['data'] as List)
              .map((item) => Prestador.fromJson(item))
              .toList();
        }
        return {'success': true, 'data': prestadores};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro na pesquisa',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Buscar serviços de um prestador
  Future<Map<String, dynamic>> buscarServicosPrestador({
    required int prestadorId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}${ApiConfig.servicoEndpoint}prestador/$prestadorId',
        ),
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
        return {'success': true, 'data': servicos};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar serviços',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Buscar disponibilidades de um prestador para uma data específica
  Future<Map<String, dynamic>> buscarDisponibilidadesPrestador({
    required int prestadorId,
    required String token,
    required DateTime data,
  }) async {
    try {
      final dataFormatada =
          '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

      final url =
          '${ApiConfig.baseUrl}${ApiConfig.disponibilidadeEndpoint}prestador/$prestadorId/data/$dataFormatada';
      print('URL da requisição: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status code: ${response.statusCode}');
      print('Resposta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        List<Disponibilidade> disponibilidades = [];

        // Verificar onde estão os dados na resposta
        if (responseData['data'] != null) {
          disponibilidades = (responseData['data'] as List).map((item) {
            // ADAPTAR os campos da API para o modelo existente
            print('Item da API: $item');

            // Criar um mapa com os campos no formato esperado pelo modelo
            Map<String, dynamic> adaptedItem = {
              'DisponibilidadeId': item['id'] ?? 0,
              'PrestadorId': item['prestadorId'] ?? 0,
              'DisponibilidadeData':
                  item['data'] ?? DateTime.now().toIso8601String(),
              'DisponibilidadeHoraInicio': item['horaInicio'] ?? '',
              'DisponibilidadeHoraFim': item['horaFim'] ?? '',
              'DisponibilidadeStatus': item['status'] ?? true,
              'prestador': item['prestador'],
            };

            return Disponibilidade.fromJson(adaptedItem);
          }).toList();
        }

        return {'success': true, 'data': disponibilidades};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar disponibilidades',
        };
      }
    } catch (e) {
      print('Erro detalhado: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> pesquisarPrestadoresPorEstabelecimento({
    required String token,
    required int estabelecimentoId,
    String? nome,
    String? telefone,
  }) async {
    try {
      // Construir query parameters
      String url =
          '${ApiConfig.baseUrl}empresa/estabelecimento/$estabelecimentoId/prestadores';

      final queryParams = <String, String>{};
      if (nome != null && nome.isNotEmpty) {
        queryParams['nome'] = nome;
      }
      if (telefone != null && telefone.isNotEmpty) {
        queryParams['telefone'] = telefone;
      }

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(Uri.parse(url), headers: _headers(token));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar prestadores',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> buscarServicosPrestadorPorEstabelecimento({
    required int prestadorId,
    required int estabelecimentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}servicoEstabelecimento/prestador/$prestadorId/estabelecimento/$estabelecimentoId',
        ),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Converter para o formato esperado pela tela (lista de Servico)
        List<Servico> servicos = [];
        if (responseData['data'] != null) {
          servicos = (responseData['data'] as List)
              .map(
                (item) => Servico.fromJson({
                  'ServicoId': item['ServicoId'],
                  'PrestadorId': prestadorId,
                  'ServicoNome': item['ServicoNome'],
                  'ServicoDescricao': item['ServicoDescricao'],
                  'ServicoTempoMedio': item['ServicoTempoMedio'],
                  'precoAtual': item['precoAtual'],
                }),
              )
              .toList();
        }
        return {'success': true, 'data': servicos};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar serviços',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> buscarDisponibilidadesPorEstabelecimento({
    required int prestadorId,
    required int estabelecimentoId,
    required String token,
    required DateTime data,
  }) async {
    try {
      // Formatar data no padrão YYYY-MM-DD
      final dataFormatada =
          '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}disponibilidade/prestador/$prestadorId/estabelecimento/$estabelecimentoId?data=$dataFormatada',
        ),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Converter para o formato esperado pela tela
        List<Disponibilidade> disponibilidades = [];
        if (responseData['data'] != null) {
          disponibilidades = (responseData['data'] as List)
              .map(
                (item) => Disponibilidade(
                  id: item['id'],
                  prestadorId: prestadorId,
                  data: DateTime.parse(item['data']),
                  horaInicio: item['horaInicio'],
                  horaFim: item['horaFim'],
                  status: item['status'],
                ),
              )
              .toList();
        }
        return {'success': true, 'data': disponibilidades};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar disponibilidades',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> buscarUltimasEmpresas(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}agendamento/cliente/ultimas-empresas'),
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
          'message':
              responseData['error'] ?? 'Erro ao carregar últimas empresas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

}
