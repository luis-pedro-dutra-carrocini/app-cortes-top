import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';

class PesquisaService {
  final String baseUrl = '${ApiConfig.baseUrl}pesquisa';

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Pesquisar prestadores
  Future<Map<String, dynamic>> pesquisarPrestadores({
    required String token,
    required String termo,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/prestadores?termo=${Uri.encodeComponent(termo)}'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao pesquisar prestadores',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Pesquisar empresas
  Future<Map<String, dynamic>> pesquisarEmpresas({
    required String token,
    required String termo,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/empresas?termo=${Uri.encodeComponent(termo)}'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao pesquisar empresas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Pesquisar estabelecimentos
  Future<Map<String, dynamic>> pesquisarEstabelecimentos({
    required String token,
    required String termo,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/estabelecimentos?termo=${Uri.encodeComponent(termo)}',
        ),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        return {
          'success': false,
          'message':
              responseData['error'] ?? 'Erro ao pesquisar estabelecimentos',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Pesquisa combinada
  Future<Map<String, dynamic>> pesquisarTodos({
    required String token,
    required String termo,
    String? tipo,
  }) async {
    try {
      String url = '$baseUrl/todos?termo=${Uri.encodeComponent(termo)}';
      if (tipo != null && tipo.isNotEmpty) {
        url += '&tipo=$tipo';
      }

      final response = await http.get(Uri.parse(url), headers: _headers(token));

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
          'message': responseData['error'] ?? 'Erro ao pesquisar',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> buscarEstabelecimentosPorEmpresa({
    required String token,
    required int empresaId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}empresa/$empresaId/estabelecimentos'),
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
