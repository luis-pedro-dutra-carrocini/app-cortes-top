import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/conApi.dart';
import '../models/modEstablishment.dart';

class EstabelecimentoService {
  final String baseUrl = '${ApiConfig.baseUrl}estabelecimento';

  // Headers padrão
  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Listar estabelecimentos da empresa
  Future<Map<String, dynamic>> listarEstabelecimentos({
    required String token,
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      String url = '$baseUrl?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }

      final response = await http.get(Uri.parse(url), headers: _headers(token));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        List<Estabelecimento> estabelecimentos = [];
        if (responseData['data'] != null) {
          estabelecimentos = (responseData['data'] as List)
              .map((item) => Estabelecimento.fromJson(item))
              .toList();
        }

        return {
          'success': true,
          'data': estabelecimentos,
          'pagination': responseData['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar estabelecimentos',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Buscar estabelecimento por ID
  Future<Map<String, dynamic>> buscarEstabelecimento({
    required int estabelecimentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$estabelecimentoId'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Estabelecimento.fromJson(responseData['data']),
          'usuarios': responseData['data']['usuarios'] ?? [],
          'servicos': responseData['data']['servicos'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao buscar estabelecimento',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Criar estabelecimento
  Future<Map<String, dynamic>> criarEstabelecimento({
    required String token,
    required String nome,
    required String telefone,
    required String rua,
    required String numero,
    String? complemento,
    required String bairro,
    required String cidade,
    required String estado,
    required String cep,
  }) async {
    try {
      final body = {
        'EstabelecimentoNome': nome.trim(),
        'EstabelecimentoTelefone': telefone.trim(),
        'EnderecoRua': rua.trim(),
        'EnderecoNumero': numero.trim(),
        'EnderecoComplemento': complemento?.trim(),
        'EnderecoBairro': bairro.trim(),
        'EnderecoCidade': cidade.trim(),
        'EnderecoEstado': estado.trim().toUpperCase(),
        'EnderecoCEP': cep.replaceAll(RegExp(r'[^0-9]'), ''),
      };

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: _headers(token),
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Estabelecimento criado com sucesso',
          'data': Estabelecimento.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao criar estabelecimento',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Atualizar estabelecimento
  Future<Map<String, dynamic>> atualizarEstabelecimento({
    required int estabelecimentoId,
    required String token,
    String? nome,
    String? telefone,
    String? status,
    String? rua,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
    String? cep,
  }) async {
    try {
      final Map<String, dynamic> body = {};

      if (nome != null) body['EstabelecimentoNome'] = nome.trim();
      if (telefone != null) body['EstabelecimentoTelefone'] = telefone.trim();
      if (status != null) body['EstabelecimentoStatus'] = status;
      if (rua != null) body['EnderecoRua'] = rua.trim();
      if (numero != null) body['EnderecoNumero'] = numero.trim();
      if (complemento != null) body['EnderecoComplemento'] = complemento.trim();
      if (bairro != null) body['EnderecoBairro'] = bairro.trim();
      if (cidade != null) body['EnderecoCidade'] = cidade.trim();
      if (estado != null) body['EnderecoEstado'] = estado.trim().toUpperCase();
      if (cep != null)
        body['EnderecoCEP'] = cep.replaceAll(RegExp(r'[^0-9]'), '');

      print('Enviando atualização: $body'); // LOG

      final response = await http.put(
        Uri.parse('$baseUrl/$estabelecimentoId'),
        headers: _headers(token),
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);
      print('Resposta: $responseData'); // LOG

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Estabelecimento atualizado com sucesso',
          'data': Estabelecimento.fromJson(responseData['data']),
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['error'] ?? 'Erro ao atualizar estabelecimento',
        };
      }
    } catch (e) {
      print('Erro no service: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Alternar status do estabelecimento
  Future<Map<String, dynamic>> alternarStatus({
    required int estabelecimentoId,
    required String token,
    required bool ativo,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$estabelecimentoId/status'),
        headers: _headers(token),
        body: json.encode({'ativo': ativo}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Status alterado com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao alterar status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar usuários vinculados
  Future<Map<String, dynamic>> listarUsuariosVinculados({
    required int estabelecimentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$estabelecimentoId/usuarios'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        List<UsuarioVinculado> usuarios = [];
        if (responseData['data'] != null) {
          usuarios = (responseData['data'] as List)
              .map((item) => UsuarioVinculado.fromJson(item))
              .toList();
        }
        return {'success': true, 'data': usuarios};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar usuários',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar vínculos do estabelecimento (todos os status)
  Future<Map<String, dynamic>> listarVinculos({
    required int estabelecimentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$estabelecimentoId/vinculos'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // REMOVA A CONVERSÃO PARA Vinculo E RETORNE OS DADOS BRUTOS
        return {
          'success': true,
          'data':
              responseData['data'] ?? [], // APENAS RETORNA O ARRAY DIRETAMENTE
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar vínculos',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Solicitar vínculo (estabelecimento solicita)
  Future<Map<String, dynamic>> solicitarVinculo({
    required int estabelecimentoId,
    required int usuarioId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$estabelecimentoId/solicitar-vinculo/$usuarioId'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Solicitação enviada com sucesso',
          'data': responseData['data'] != null
              ? Vinculo.fromJson(responseData['data'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao solicitar vínculo',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Aceitar solicitação de vínculo
  Future<Map<String, dynamic>> aceitarVinculo({
    required int vinculoId,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vinculos/$vinculoId/aceitar'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Vínculo aceito com sucesso',
          'data': responseData['data'] != null
              ? Vinculo.fromJson(responseData['data'])
              : null,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao aceitar vínculo',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Recusar solicitação de vínculo
  Future<Map<String, dynamic>> recusarVinculo({
    required int vinculoId,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vinculos/$vinculoId/recusar'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Solicitação recusada',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao recusar solicitação',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Desativar/Excluir vínculo (estabelecimento pode desativar/excluir)
  Future<Map<String, dynamic>> desativarVinculo({
    required int vinculoId,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vinculos/$vinculoId/desativar'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Vínculo excluído',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao excluir vínculo',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Excluir vínculo (soft delete)
  Future<Map<String, dynamic>> excluirVinculo({
    required int vinculoId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vinculos/$vinculoId'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Vínculo excluído',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao excluir vínculo',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar prestadores disponíveis para vincular (com busca)
  Future<Map<String, dynamic>> listarPrestadoresDisponiveis({
    required int estabelecimentoId,
    required String token,
    String? busca,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url =
          '$baseUrl/$estabelecimentoId/prestadores-disponiveis?page=$page&limit=$limit';
      if (busca != null && busca.isNotEmpty) {
        url += '&busca=$busca';
      }

      final response = await http.get(Uri.parse(url), headers: _headers(token));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? [],
          'pagination': responseData['pagination'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['error'] ?? 'Erro ao listar prestadores disponíveis',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Vincular usuário ao estabelecimento
  Future<Map<String, dynamic>> vincularUsuario({
    required int estabelecimentoId,
    required int usuarioId,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$estabelecimentoId/usuarios/$usuarioId'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Usuário vinculado com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao vincular usuário',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Desvincular usuário do estabelecimento
  Future<Map<String, dynamic>> desvincularUsuario({
    required int estabelecimentoId,
    required int usuarioId,
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$estabelecimentoId/usuarios/$usuarioId'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Usuário desvinculado com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao desvincular usuário',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar vínculos do prestador
  Future<Map<String, dynamic>> listarVinculosPrestador({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}estabelecimento/prestador/vinculos/todos',
        ),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar vínculos',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Reativar vínculo
  Future<Map<String, dynamic>> reativarVinculo({
    required int vinculoId,
    required String token,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/vinculos/$vinculoId/reativar'),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Vínculo reativado com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao reativar vínculo',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar serviços do estabelecimento
  Future<Map<String, dynamic>> listarServicosEstabelecimento({
    required int estabelecimentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}servicoEstabelecimento/estabelecimento/$estabelecimentoId',
        ),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar serviços',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Cadastrar serviço do estabelecimento
  Future<Map<String, dynamic>> cadastrarServicoEstabelecimento({
    required int estabelecimentoId,
    required String nome,
    String? descricao,
    required int tempoMedio,
    required String token,
  }) async {
    try {
      final body = {
        'EstabelecimentoId': estabelecimentoId,
        'ServicoNome': nome.trim(),
        'ServicoDescricao': descricao?.trim().isEmpty ?? true
            ? null
            : descricao?.trim(),
        'ServicoTempoMedio': tempoMedio,
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}servicoEstabelecimento'),
        headers: _headers(token),
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Serviço cadastrado com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao cadastrar serviço',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar prestadores disponíveis para vincular a um serviço
  Future<Map<String, dynamic>> listarPrestadoresDisponiveisParaServico({
    required int servicoEstabelecimentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}servicoEstabelecimento/$servicoEstabelecimentoId/prestadores-disponiveis',
        ),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar prestadores',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar prestadores vinculados a um serviço
  Future<Map<String, dynamic>> listarPrestadoresVinculados({
    required int servicoEstabelecimentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}servicoEstabelecimento/$servicoEstabelecimentoId/prestadores-vinculados',
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
              responseData['error'] ?? 'Erro ao listar prestadores vinculados',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Vincular serviço a um prestador
  Future<Map<String, dynamic>> vincularServicoAPrestador({
    required int servicoEstabelecimentoId,
    required int prestadorId,
    double? valorInicial,
    required String token,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (valorInicial != null && valorInicial > 0) {
        body['ServicoValor'] = valorInicial;
      }

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}servicoEstabelecimento/$servicoEstabelecimentoId/vincular/$prestadorId',
        ),
        headers: _headers(token),
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Serviço vinculado com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao vincular serviço',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Desvincular serviço de um prestador
  Future<Map<String, dynamic>> desvincularServicoDePrestador({
    required int servicoId, // ID do serviço vinculado (na tabela Servico)
    required String token,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}servicoEstabelecimento/vincular/$servicoId',
        ),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Serviço desvinculado com sucesso'};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao desvincular serviço',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Listar serviços do estabelecimento (todos)
  Future<Map<String, dynamic>> listarTodosServicosEstabelecimento({
    required int estabelecimentoId,
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}servicoEstabelecimento/estabelecimento/$estabelecimentoId/todos',
        ),
        headers: _headers(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao listar serviços',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Atualizar serviço do estabelecimento
  Future<Map<String, dynamic>> atualizarServicoEstabelecimento({
    required int servicoId,
    required String nome,
    String? descricao,
    required int tempoMedio,
    required bool ativo,
    required String token,
  }) async {
    try {
      final body = {
        'ServicoNome': nome.trim(),
        'ServicoDescricao': descricao?.trim().isEmpty ?? true
            ? null
            : descricao?.trim(),
        'ServicoTempoMedio': tempoMedio,
        'ServicoAtivo': ativo,
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}servicoEstabelecimento/$servicoId'),
        headers: _headers(token),
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Serviço atualizado com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao atualizar serviço',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Atualizar preço unificado para todos os prestadores vinculados a um serviço do estabelecimento
  Future<Map<String, dynamic>> atualizarPrecoUnificadoServico({
    required int servicoEstabelecimentoId,
    required double valor,
    required String token,
  }) async {
    try {
      final body = {'ServicoValor': valor};

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}servicoPreco/servico-estabelecimento/$servicoEstabelecimentoId/preco-unificado',
        ),
        headers: _headers(token),
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Preço atualizado com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao atualizar preço',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Adicionar preço a um serviço individual
  Future<Map<String, dynamic>> adicionarPrecoServico({
    required int servicoId,
    required double valor,
    required String token,
  }) async {
    try {
      final body = {'ServicoValor': valor};

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}servicoPreco/servico/$servicoId'),
        headers: _headers(token),
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Preço adicionado com sucesso',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Erro ao adicionar preço',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}
