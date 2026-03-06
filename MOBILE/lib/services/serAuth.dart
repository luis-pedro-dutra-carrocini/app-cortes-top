import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/modUser.dart';
import '../config/conApi.dart';

class AuthService {
  static const String _tokenKey = 'token';
  static const String _userDataKey = 'user_data';

  // Salvar dados do usuário após login
  Future<void> saveUserData(String token, Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userDataKey, json.encode(usuario.toJsonCompleto())); 
  }

  // Recuperar usuário logado
  Future<Usuario?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    if (userData != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(userData);
        return Usuario.fromJson(jsonMap);
      } catch (e) {
        print('Erro ao decodificar usuário: $e');
        return null;
      }
    }
    return null;
  }

  // Recuperar token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Verificar se usuário está logado
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  // Validar token com o backend
  Future<Map<String, dynamic>> validarToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/validar-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'valido': true,
          'usuario': Usuario.fromJson(data['usuario']),
        };
      } else {
        return {'valido': false, 'usuario': null};
      }
    } catch (e) {
      print('Erro ao validar token: $e');
      return {'valido': false, 'usuario': null};
    }
  }

  // Verificar autenticação completa (token existe e é válido)
  Future<Map<String, dynamic>> verificarAutenticacao() async {
    final token = await getToken();
    
    if (token == null) {
      return {'autenticado': false, 'usuario': null};
    }

    final validacao = await validarToken(token);
    
    if (validacao['valido']) {
      return {
        'autenticado': true,
        'usuario': validacao['usuario'],
        'token': token,
      };
    } else {
      // Token inválido, limpar dados
      await logout();
      return {'autenticado': false, 'usuario': null};
    }
  }

  // Fazer logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
  }

  // Obter tipo do usuário logado
  Future<String?> getUserType() async {
    final user = await getCurrentUser();
    return user?.tipo;
  }
}