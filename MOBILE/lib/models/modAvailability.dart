class Disponibilidade {
  final int id;
  final int prestadorId;
  final DateTime data;
  final String horaInicio;
  final String horaFim;
  final bool status;
  final Map<String, dynamic>? prestador;

  Disponibilidade({
    required this.id,
    required this.prestadorId,
    required this.data,
    required this.horaInicio,
    required this.horaFim,
    required this.status,
    this.prestador,
  });

  factory Disponibilidade.fromJson(Map<String, dynamic> json) {
    return Disponibilidade(
      id: json['DisponibilidadeId'] ?? 0,
      prestadorId: json['PrestadorId'] ?? 0,
      data: json['DisponibilidadeData'] != null
          ? DateTime.parse(json['DisponibilidadeData'])
          : DateTime.now(),
      horaInicio: json['DisponibilidadeHoraInicio'] ?? '',
      horaFim: json['DisponibilidadeHoraFim'] ?? '',
      status: json['DisponibilidadeStatus'] ?? true,
      prestador: json['prestador'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'DisponibilidadeHoraInicio': horaInicio,
      'DisponibilidadeHoraFim': horaFim,
    };
  }

  String get horarioFormatado => '$horaInicio - $horaFim';

  String get dataFormatada {
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }

  String get diaSemana {
    const dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return dias[data.weekday % 7];
  }

  String get diaSemanaCompleto {
    const dias = [
      'Domingo',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
    ];
    return dias[data.weekday % 7];
  }
}

class DisponibilidadeAgrupada {
  final String data;
  final String dataFormatada;
  final int diaSemana;
  final String diaSemanaDescricao;
  final List<Disponibilidade> disponibilidades;

  DisponibilidadeAgrupada({
    required this.data,
    required this.dataFormatada,
    required this.diaSemana,
    required this.diaSemanaDescricao,
    required this.disponibilidades,
  });

  factory DisponibilidadeAgrupada.fromJson(Map<String, dynamic> json) {
    return DisponibilidadeAgrupada(
      data: json['data'] ?? '',
      dataFormatada: json['dataFormatada'] ?? '',
      diaSemana: json['diaSemana'] ?? 0,
      diaSemanaDescricao: json['diaSemanaDescricao'] ?? '',
      disponibilidades:
          (json['disponibilidades'] as List?)
              ?.map((item) => Disponibilidade.fromJson(item))
              .toList() ??
          [],
    );
  }

  String get diaSemanaAbreviado {
    const diasAbrev = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return diasAbrev[diaSemana];
  }
}
