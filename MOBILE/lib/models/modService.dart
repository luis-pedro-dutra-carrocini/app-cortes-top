class Servico {
  final int id;
  final int prestadorId;
  final String nome;
  final String? descricao;
  final int tempoMedio; // em minutos
  final bool ativo;
  final double? precoAtual;
  final Map<String, dynamic>? ultimoPreco;
  final Map<String, dynamic>? prestador;

  Servico({
    required this.id,
    required this.prestadorId,
    required this.nome,
    this.descricao,
    required this.tempoMedio,
    required this.ativo,
    this.precoAtual,
    this.ultimoPreco,
    this.prestador,
  });

  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      id: json['ServicoId'] ?? 0,
      prestadorId: json['PrestadorId'] ?? 0,
      nome: json['ServicoNome'] ?? '',
      descricao: json['ServicoDescricao'],
      tempoMedio: json['ServicoTempoMedio'] ?? 0,
      ativo: json['ServicoAtivo'] ?? true,
      precoAtual: json['precoAtual'] != null 
          ? (json['precoAtual'] is int 
              ? (json['precoAtual'] as int).toDouble() 
              : json['precoAtual']) 
          : null,
      ultimoPreco: json['ultimoPreco'],
      prestador: json['prestador'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ServicoNome': nome,
      'ServicoDescricao': descricao,
      'ServicoTempoMedio': tempoMedio,
      'ServicoAtivo': ativo,
    };
  }

  Servico copyWith({
    int? id,
    int? prestadorId,
    String? nome,
    String? descricao,
    int? tempoMedio,
    bool? ativo,
    double? precoAtual,
    Map<String, dynamic>? ultimoPreco,
    Map<String, dynamic>? prestador,
  }) {
    return Servico(
      id: id ?? this.id,
      prestadorId: prestadorId ?? this.prestadorId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      tempoMedio: tempoMedio ?? this.tempoMedio,
      ativo: ativo ?? this.ativo,
      precoAtual: precoAtual ?? this.precoAtual,
      ultimoPreco: ultimoPreco ?? this.ultimoPreco,
      prestador: prestador ?? this.prestador,
    );
  }
}

class PrecoServico {
  final int id;
  final int servicoId;
  final double valor;
  final DateTime dataCriacao;

  PrecoServico({
    required this.id,
    required this.servicoId,
    required this.valor,
    required this.dataCriacao,
  });

  factory PrecoServico.fromJson(Map<String, dynamic> json) {
    return PrecoServico(
      id: json['ServicoPrecoId'] ?? 0,
      servicoId: json['ServicoId'] ?? 0,
      valor: json['ServicoValor'] != null 
          ? (json['ServicoValor'] is int 
              ? (json['ServicoValor'] as int).toDouble() 
              : json['ServicoValor']) 
          : 0,
      dataCriacao: json['ServicoPrecoDtCriacao'] != null 
          ? DateTime.parse(json['ServicoPrecoDtCriacao']) 
          : DateTime.now(),
    );
  }
}