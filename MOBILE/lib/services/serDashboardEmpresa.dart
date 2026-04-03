import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';

class DashboardEmpresaService {
  final String baseUrl = '${ApiConfig.baseUrl}dashboard-empresa';

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> obterDashboard({
    required String token,
    String tipo = 'mes',
    int? estabelecimentoId,
  }) async {
    try {
      String url = '$baseUrl?tipo=$tipo';
      if (estabelecimentoId != null) {
        url += '&estabelecimentoId=$estabelecimentoId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers(token),
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
          'message': responseData['error'] ?? 'Erro ao carregar dashboard',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> obterResumoRapido(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resumo'),
        headers: _headers(token),
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
          'message': responseData['error'] ?? 'Erro ao carregar resumo',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}