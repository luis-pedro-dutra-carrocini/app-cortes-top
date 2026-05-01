import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modUser.dart';

class ApiService {
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
  
  // Login com Google
  Future<Map<String, dynamic>> loginWithGoogle({
    required String googleToken,
    required String tipo,
    String? tipoRequisicao,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}login/google'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'googleToken': googleToken,
          'usuarioTipo': tipo,
          'tipoRequisicao': tipoRequisicao ?? 'LOGIN',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final usuario = Usuario.fromJson(data['usuario']);
        return {
          'success': true,
          'token': data['token'],
          'usuario': usuario,
          'message': data['message'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Erro ao fazer login com Google',
        };
      }
    } catch (e) {
      print('Erro na requisição: $e');
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

}
