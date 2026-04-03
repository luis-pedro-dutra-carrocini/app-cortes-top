import 'package:flutter/material.dart';

class AgendamentoEmpresa {
  final int id;
  final int prestadorId;
  final int clienteId;
  final int? disponibilidadeId;
  final int? estabelecimentoId;
  final DateTime dataServico;
  final String horaServico;
  final String status;
  final double valorTotal;
  final int tempoGasto;
  final String? observacao;
  final String? descricaoTrabalho;
  final String clienteNome;
  final String clienteTelefone;
  final String prestadorNome;
  final String? estabelecimentoNome;
  final String? empresaNome;
  final String? endereco;
  final String? contatoTelefone;
  final List<Map<String, dynamic>> servicos;

  AgendamentoEmpresa({
    required this.id,
    required this.prestadorId,
    required this.clienteId,
    this.disponibilidadeId,
    this.estabelecimentoId,
    required this.dataServico,
    required this.horaServico,
    required this.status,
    required this.valorTotal,
    required this.tempoGasto,
    this.observacao,
    this.descricaoTrabalho,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.prestadorNome,
    this.estabelecimentoNome,
    this.empresaNome,
    this.endereco,
    this.contatoTelefone,
    required this.servicos,
  });

  factory AgendamentoEmpresa.fromJson(Map<String, dynamic> json) {
    final prestador = json['prestador'] ?? {};
    final cliente = json['cliente'] ?? {};
    final estabelecimento = json['estabelecimento'] ?? {};
    final empresa = estabelecimento['empresa'] ?? {};

    return AgendamentoEmpresa(
      id: json['AgendamentoId'] ?? 0,
      prestadorId: json['PrestadorId'] ?? 0,
      clienteId: json['ClienteId'] ?? 0,
      disponibilidadeId: json['DisponibilidadeId'],
      estabelecimentoId: json['EstabelecimentoId'],
      dataServico: json['AgendamentoDtServico'] != null
          ? DateTime.parse(json['AgendamentoDtServico'])
          : DateTime.now(),
      horaServico: json['AgendamentoHoraServico'] ?? '',
      status: json['AgendamentoStatus'] ?? 'PENDENTE',
      valorTotal: json['AgendamentoValorTotal'] != null
          ? (json['AgendamentoValorTotal'] is int
                ? (json['AgendamentoValorTotal'] as int).toDouble()
                : json['AgendamentoValorTotal'])
          : 0,
      tempoGasto: json['AgendamentoTempoGasto'] ?? 0,
      observacao: json['AgendamentoObservacao'],
      descricaoTrabalho: json['AgendamentoDescricaoTrabalho'],
      clienteNome: cliente['UsuarioNome'] ?? 'Cliente',
      clienteTelefone: cliente['UsuarioTelefone'] ?? '',
      prestadorNome: prestador['UsuarioNome'] ?? 'Prestador',
      estabelecimentoNome: estabelecimento['EstabelecimentoNome'],
      empresaNome: empresa['EmpresaNome'],
      endereco: json['endereco'],
      contatoTelefone: json['contatoTelefone'],
      servicos: List<Map<String, dynamic>>.from(json['servicos'] ?? []),
    );
  }

  String get dataFormatada {
    return '${dataServico.day.toString().padLeft(2, '0')}/'
        '${dataServico.month.toString().padLeft(2, '0')}/'
        '${dataServico.year}';
  }

  String get horarioFormatado {
    return '$horaServico';
  }

  Color get statusColor {
    switch (status) {
      case 'PENDENTE':
        return Colors.orange;
      case 'CONFIRMADO':
        return Colors.green;
      case 'EM_ANDAMENTO':
        return Colors.blue;
      case 'CONCLUIDO':
        return Colors.purple;
      case 'CANCELADO':
        return Colors.red;
      case 'RECUSADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get statusDescricao {
    if (status == 'EM_ANDAMENTO') return 'EM ATENDIMENTO';
    return status;
  }

  String get tituloDescricao {
    switch (status) {
      case 'CONCLUIDO':
        return 'Descrição do Trabalho Realizado';
      case 'RECUSADO':
        return 'Motivo da Recusa';
      case 'CANCELADO':
        return 'Motivo do Cancelamento';
      default:
        return 'Descrição';
    }
  }

  bool get mostrarDescricao {
    return status == 'CONCLUIDO' || status == 'RECUSADO' || status == 'CANCELADO';
  }
}