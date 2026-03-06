import 'package:flutter/material.dart';

class AgendamentoPrestador {
  final int id;
  final int clienteId;
  final String clienteNome;
  final String clienteTelefone;
  final DateTime dataServico;
  final String horaServico;
  final String status;
  String statusDescricao; // Campo para exibir o status de forma mais amigável
  final double valorTotal;
  final int tempoGasto;
  final String? observacao;
  final List<dynamic> servicos;
  String? descricaoTrabalho; // Campo para preencher ao finalizar

  AgendamentoPrestador({
    required this.id,
    required this.clienteId,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.dataServico,
    required this.horaServico,
    required this.status,
    required this.statusDescricao,
    required this.valorTotal,
    required this.tempoGasto,
    this.observacao,
    required this.servicos,
    this.descricaoTrabalho,
  });

  factory AgendamentoPrestador.fromJson(Map<String, dynamic> json) {
    // Extrair dados do cliente
    final cliente = json['cliente'] ?? {};

    return AgendamentoPrestador(
      id: json['AgendamentoId'] ?? 0,
      clienteId: cliente['UsuarioId'] ?? 0,
      clienteNome: cliente['UsuarioNome'] ?? 'Cliente',
      clienteTelefone: cliente['UsuarioTelefone'] ?? '',
      dataServico: json['AgendamentoDtServico'] != null
          ? DateTime.parse(json['AgendamentoDtServico'])
          : DateTime.now(),
      horaServico: json['AgendamentoHoraServico'] ?? '',
      status: json['AgendamentoStatus'] ?? 'PENDENTE',
      statusDescricao: json['AgendamentoStatus'] ?? 'PENDENTE',
      valorTotal: json['AgendamentoValorTotal'] != null
          ? (json['AgendamentoValorTotal'] is int
                ? (json['AgendamentoValorTotal'] as int).toDouble()
                : json['AgendamentoValorTotal'])
          : 0,
      tempoGasto: json['AgendamentoTempoGasto'] ?? 0,
      observacao: json['AgendamentoObservacao'],
      servicos: json['servicos'] ?? [],
      descricaoTrabalho: json['AgendamentoDescricaoTrabalho'],
    );
  }

  String get dataFormatada {
    return '${dataServico.day.toString().padLeft(2, '0')}/'
        '${dataServico.month.toString().padLeft(2, '0')}/'
        '${dataServico.year}';
  }

  // Getters para controle de ações baseado no status
  bool get podeConfirmar => status == 'PENDENTE';
  bool get podeIniciar => status == 'CONFIRMADO';
  bool get podeVoltarPendente => status == 'CONFIRMADO';
  bool get podeFinalizar => status == 'EM_ANDAMENTO';
  bool get podeCancelar =>
      status == 'PENDENTE' ||
      status ==
          'CONFIRMADO'; // Só pode cancelar se estiver pendente ou confirmado
  bool get podeRecusar =>
      status == 'PENDENTE'; // Só pode recusar se estiver pendente

  // Cores para cada status
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
      default:
        return Colors.grey;
    }
  }

  // Getter para título da descrição baseado no status
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

  // Verificar se deve mostrar o campo de descrição
  bool get mostrarDescricao {
    return status == 'CONCLUIDO' ||
        status == 'RECUSADO' ||
        status == 'CANCELADO';
  }

  AgendamentoPrestador copyWith({String? status, String? descricaoTrabalho}) {
    return AgendamentoPrestador(
      id: id,
      clienteId: clienteId,
      clienteNome: clienteNome,
      clienteTelefone: clienteTelefone,
      dataServico: dataServico,
      horaServico: horaServico,
      status: status ?? this.status,
      statusDescricao: status ?? this.status,
      valorTotal: valorTotal,
      tempoGasto: tempoGasto,
      observacao: observacao,
      servicos: servicos,
      descricaoTrabalho: descricaoTrabalho ?? this.descricaoTrabalho,
    );
  }
}
