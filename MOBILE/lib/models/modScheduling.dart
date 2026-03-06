class Agendamento {
  final int id;
  final int prestadorId;
  final int clienteId;
  final DateTime dataServico;
  final String horaServico;
  final String status;
  final double valorTotal;
  final int tempoGasto;
  final String? observacao;
  final int? disponibilidadeId;
  final Map<String, dynamic>? prestador;
  final Map<String, dynamic>? cliente;
  final List<dynamic>? servicos;

  Agendamento({
    required this.id,
    required this.prestadorId,
    required this.clienteId,
    required this.dataServico,
    required this.horaServico,
    required this.status,
    required this.valorTotal,
    required this.tempoGasto,
    this.disponibilidadeId,
    this.observacao,
    this.prestador,
    this.cliente,
    this.servicos,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['AgendamentoId'] ?? 0,
      prestadorId: json['PrestadorId'] ?? 0,
      clienteId: json['ClienteId'] ?? 0,
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
      prestador: json['prestador'],
      cliente: json['cliente'],
      servicos: json['servicos'],
    );
  }

  String get dataFormatada {
    return '${dataServico.day.toString().padLeft(2, '0')}/'
        '${dataServico.month.toString().padLeft(2, '0')}/'
        '${dataServico.year}';
  }

  bool get podeEditar {
    return status == 'PENDENTE';
  }

  bool get podeCancelar {
    return status == 'PENDENTE' || status == 'CONFIRMADO';
  }
}
