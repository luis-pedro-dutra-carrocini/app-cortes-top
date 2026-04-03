import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modUser.dart';

class UsuarioService {
  Future<Map<String, dynamic>> buscarUsuario(
    int usuarioId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}$usuarioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Usuario.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar usuário',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> atualizarUsuario({
    required int usuarioId,
    required String token,
    required Map<String, dynamic> dados,
  }) async {
    try {
      final Map<String, dynamic> body = {};

      // Mapear campos padrão
      if (dados.containsKey('nome')) body['UsuarioNome'] = dados['nome'];
      if (dados.containsKey('telefone'))
        body['UsuarioTelefone'] = dados['telefone'];
      if (dados.containsKey('email')) body['UsuarioEmail'] = dados['email'];
      if (dados.containsKey('senha')) body['UsuarioSenha'] = dados['senha'];

      // Mapear campos de endereço
      if (dados.containsKey('cep')) body['EnderecoCEP'] = dados['cep'];
      if (dados.containsKey('rua')) body['EnderecoRua'] = dados['rua'];
      if (dados.containsKey('numero')) body['EnderecoNumero'] = dados['numero'];
      if (dados.containsKey('complemento'))
        body['EnderecoComplemento'] = dados['complemento'];
      if (dados.containsKey('bairro')) body['EnderecoBairro'] = dados['bairro'];
      if (dados.containsKey('cidade')) body['EnderecoCidade'] = dados['cidade'];
      if (dados.containsKey('estado')) body['EnderecoEstado'] = dados['estado'];

      // Mapear CNPJ
      if (dados.containsKey('cnpj')) body['EmpresaCNPJ'] = dados['cnpj'];

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}$usuarioId'),
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
          'message': responseData['message'] ?? 'Perfil atualizado com sucesso',
          'data': Usuario.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao atualizar perfil',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> excluirUsuario(
    int usuarioId,
    String token,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuarioEndpoint}$usuarioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Conta excluída com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao excluir conta',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}
