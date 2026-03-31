import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';

class DashboardService {
  
  // Obter resumo rápido para a home
  Future<Map<String, dynamic>> obterResumoRapido(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.dashboardEndpoint}resumo-rapido'),
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
          'message': responseData['error'] ?? 'Erro ao carregar resumo',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      };
    }
  }

  // Obter dashboard completo (para futura implementação)
  Future<Map<String, dynamic>> obterDashboard({
    required String token,
    required String tipo, // 'ano', 'mes', 'dia'
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}dashboard?tipo=$tipo'),
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
          'message': responseData['error'] ?? 'Erro ao carregar dashboard',
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