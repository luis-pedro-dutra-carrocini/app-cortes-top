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
        //print('Erro ao decodificar usuário: $e');
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
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}validar-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));
      //print('token: ${token}');
      //print('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        //print('response.body = ' + response.body);
        final data = json.decode(response.body);
        return {
          'valido': true,
          'usuario': Usuario.fromJson(data['usuario']),
        };
      } else {
        //print('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
        return {'valido': false, 'usuario': null};
      }
    } catch (e) {
      //print('Erro ao validar token: $e');
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
    //print('validacao = ' + validacao.toString());
    
    if (validacao['valido'] == true) {
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
    final token = prefs.getString(_tokenKey);

    await http
    .post(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }
    )
    .timeout(const Duration(seconds: 10));

    //print('token: ${token}');
    //print('Status code: ${response.statusCode}');
    //print('Resposta: ${response.body}');

    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
  }

  // Obter tipo do usuário logado
  Future<String?> getUserType() async {
    final user = await getCurrentUser();
    return user?.tipo;
  }

  // Cadastrar novo usuário
  Future<Map<String, dynamic>> cadastrarUsuario(
    Map<String, dynamic> dados,
  ) async {
    try {
      //print(
      //  'Enviando requisição para: ${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}cadastrar',
      //);
      //print('Dados: $dados');

      // Mapear os campos para o formato esperado pelo backend
      final Map<String, dynamic> body = {
        'UsuarioNome': dados['nome'].trim(),
        'UsuarioTelefone': dados['telefone'].trim(),
        'UsuarioEmail': dados['email'].trim().toLowerCase(),
        'UsuarioSenha': dados['senha'],
        'UsuarioTipo': dados['tipo'],
      };

      // Adicionar campos de endereço se existirem
      if (dados.containsKey('rua')) {
        body['EnderecoRua'] = dados['rua'];
      }
      if (dados.containsKey('numero')) {
        body['EnderecoNumero'] = dados['numero'];
      }
      if (dados.containsKey('complemento') && dados['complemento'] != null) {
        body['EnderecoComplemento'] = dados['complemento'];
      }
      if (dados.containsKey('bairro')) {
        body['EnderecoBairro'] = dados['bairro'];
      }
      if (dados.containsKey('cidade')) {
        body['EnderecoCidade'] = dados['cidade'];
      }
      if (dados.containsKey('estado')) {
        body['EnderecoEstado'] = dados['estado'];
      }
      if (dados.containsKey('cep')) {
        body['EnderecoCEP'] = dados['cep'];
      }

      if (dados.containsKey('cnpj')) {
        body['EmpresaCNPJ'] = dados['cnpj']; // <-- Enviar como EmpresaCNPJ
      }

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}cadastrar',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      //print('Status code: ${response.statusCode}');
      //print('Resposta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Cadastro realizado com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao cadastrar',
        };
      }
    } catch (e) {
      //print('Erro na requisição: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Verifique se o servidor está rodando.',
      };
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String senha,
    required String tipo,
  }) async {
    try {
      //print(
      //  'Enviando requisição de login para: ${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}login',
      //);
      //print('Dados: email=$email, tipo=$tipo');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'UsuarioEmail': email.trim().toLowerCase(),
              'UsuarioSenha': senha,
              'UsuarioTipo': tipo,
            }),
          )
          .timeout(const Duration(seconds: 10));

      //print('Status code: ${response.statusCode}');
      //print('Resposta: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // O backend já deve retornar todos os campos necessários
        return {
          'success': true,
          'message': responseData['message'] ?? 'Login realizado com sucesso',
          'token': responseData['token'],
          'usuario': Usuario.fromJson(responseData['usuario']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao fazer login',
        };
      }
    } catch (e) {
      //print('Erro na requisição de login: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Verifique sua internet e tente novamente.',
      };
    }
  }

}