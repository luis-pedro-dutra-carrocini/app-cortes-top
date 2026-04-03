import 'package:flutter/material.dart';

class Estabelecimento {
  int? id;
  int empresaId;
  String nome;
  String telefone;
  String status;
  DateTime? dataCriacao;
  
  // Endereço
  int? enderecoId;
  String? rua;
  String? numero;
  String? complemento;
  String? bairro;
  String? cidade;
  String? estado;
  String? cep;
  
  // Dados adicionais
  int? totalUsuarios;

  Estabelecimento({
    this.id,
    required this.empresaId,
    required this.nome,
    required this.telefone,
    required this.status,
    this.dataCriacao,
    this.enderecoId,
    this.rua,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    this.totalUsuarios,
  });

  factory Estabelecimento.fromJson(Map<String, dynamic> json) {
    return Estabelecimento(
      id: json['EstabelecimentoId'],
      empresaId: json['EmpresaId'],
      nome: json['EstabelecimentoNome'],
      telefone: json['EstabelecimentoTelefone'],
      status: json['EstabelecimentoStatus'],
      dataCriacao: json['EstabelecimentoDtCriacao'] != null
          ? DateTime.parse(json['EstabelecimentoDtCriacao'])
          : null,
      enderecoId: json['endereco']?['EnderecoId'],
      rua: json['endereco']?['EnderecoRua'],
      numero: json['endereco']?['EnderecoNumero'],
      complemento: json['endereco']?['EnderecoComplemento'],
      bairro: json['endereco']?['EnderecoBairro'],
      cidade: json['endereco']?['EnderecoCidade'],
      estado: json['endereco']?['EnderecoEstado'],
      cep: json['endereco']?['EnderecoCEP'],
      totalUsuarios: json['totalUsuarios'],
    );
  }

  // Método para converter para Map (para enviar para o formulário)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresaId': empresaId,
      'nome': nome,
      'telefone': telefone,
      'status': status,
      'dataCriacao': dataCriacao?.toIso8601String(),
      'enderecoId': enderecoId,
      'rua': rua,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'totalUsuarios': totalUsuarios,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'EstabelecimentoId': id,
      'EmpresaId': empresaId,
      'EstabelecimentoNome': nome,
      'EstabelecimentoTelefone': telefone,
      'EstabelecimentoStatus': status,
      'EstabelecimentoDtCriacao': dataCriacao?.toIso8601String(),
    };
  }
}

class UsuarioVinculado {
  int? id;
  String nome;
  String email;
  String telefone;
  String tipo;
  String status;

  UsuarioVinculado({
    this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.tipo,
    required this.status,
  });

  factory UsuarioVinculado.fromJson(Map<String, dynamic> json) {
    return UsuarioVinculado(
      id: json['UsuarioId'],
      nome: json['UsuarioNome'],
      email: json['UsuarioEmail'],
      telefone: json['UsuarioTelefone'],
      tipo: json['UsuarioTipo'],
      status: json['UsuarioStatus'],
    );
  }
}

enum VinculoStatus {
  ATIVO,
  SOLICITADOEST,
  SOLICITADOPRE,
  INATIVO,
  EXCLUIDO,
  BLOQUEADO
}

class Vinculo {
  int? id;
  int usuarioId;
  int estabelecimentoId;
  DateTime? dataCriacao;
  VinculoStatus status;
  Map<String, dynamic>? usuario;
  Map<String, dynamic>? estabelecimento;

  Vinculo({
    this.id,
    required this.usuarioId,
    required this.estabelecimentoId,
    this.dataCriacao,
    required this.status,
    this.usuario,
    this.estabelecimento,
  });

  factory Vinculo.fromJson(Map<String, dynamic> json) {
    return Vinculo(
      id: json['UsuarioEstabelecimentoId'],
      usuarioId: json['UsuarioId'],
      estabelecimentoId: json['EstabelecimentoId'],
      dataCriacao: json['UsuarioEstabelecimentoDtCriacao'] != null
          ? DateTime.parse(json['UsuarioEstabelecimentoDtCriacao'])
          : null,
      status: _parseStatus(json['UsuarioEstabelecimentoStatus']),
      usuario: json['usuario'],
      estabelecimento: json['estabelecimento'],
    );
  }

  static VinculoStatus _parseStatus(String? status) {
    switch (status) {
      case 'ATIVO':
        return VinculoStatus.ATIVO;
      case 'SOLICITADOEST':
        return VinculoStatus.SOLICITADOEST;
      case 'SOLICITADOPRE':
        return VinculoStatus.SOLICITADOPRE;
      case 'INATIVO':
        return VinculoStatus.INATIVO;
      case 'EXCLUIDO':
        return VinculoStatus.EXCLUIDO;
      case 'BLOQUEADO':
        return VinculoStatus.BLOQUEADO;
      default:
        return VinculoStatus.INATIVO;
    }
  }

  String get statusText {
    switch (status) {
      case VinculoStatus.ATIVO:
        return 'Ativo';
      case VinculoStatus.SOLICITADOEST:
        return 'Solicitado pelo Estabelecimento';
      case VinculoStatus.SOLICITADOPRE:
        return 'Solicitado pelo Prestador';
      case VinculoStatus.INATIVO:
        return 'Inativo';
      case VinculoStatus.EXCLUIDO:
        return 'Excluído';
      case VinculoStatus.BLOQUEADO:
        return 'Bloqueado';
    }
  }

  Color get statusColor {
    switch (status) {
      case VinculoStatus.ATIVO:
        return Colors.green;
      case VinculoStatus.SOLICITADOEST:
      case VinculoStatus.SOLICITADOPRE:
        return Colors.orange;
      case VinculoStatus.INATIVO:
      case VinculoStatus.EXCLUIDO:
      case VinculoStatus.BLOQUEADO:
        return Colors.red;
    }
  }
}