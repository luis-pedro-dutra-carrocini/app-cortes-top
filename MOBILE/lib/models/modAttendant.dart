class Prestador {
  final int id;
  final String nome;
  final String email;
  final String telefone;
  final String tipo;

  Prestador({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.tipo,
  });

  factory Prestador.fromJson(Map<String, dynamic> json) {
    return Prestador(
      id: json['UsuarioId'] ?? 0,
      nome: json['UsuarioNome'] ?? '',
      email: json['UsuarioEmail'] ?? '',
      telefone: json['UsuarioTelefone'] ?? '',
      tipo: json['UsuarioTipo'] ?? '',
    );
  }
}