class Usuario {
  final int? id;
  final String nome;
  final String telefone;
  final String email;
  final String tipo;
  DateTime? dataCriacao;
  bool ativo;

  // Campos específicos para PRESTADOR
  String? cep;
  String? rua;
  String? numero;
  String? complemento;
  String? bairro;
  String? cidade;
  String? estado;

  // Campos específicos para EMPRESA
  String? cnpj;

  Usuario({
    this.id,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.tipo,
    this.dataCriacao,
    this.ativo = true,
    this.cep,
    this.rua,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.cnpj,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['UsuarioId'],
      nome: json['UsuarioNome'],
      telefone: json['UsuarioTelefone'],
      email: json['UsuarioEmail'],
      tipo: json['UsuarioTipo'],
      dataCriacao: json['UsuarioDtCriacao'] != null
          ? DateTime.parse(json['UsuarioDtCriacao'])
          : null,
      ativo: json['UsuarioAtivo'] ?? true,
      // Endereço
      cep: json['EnderecoCEP'],
      rua: json['EnderecoRua'],
      numero: json['EnderecoNumero'],
      complemento: json['EnderecoComplemento'],
      bairro: json['EnderecoBairro'],
      cidade: json['EnderecoCidade'],
      estado: json['EnderecoEstado'],
      // CNPJ para empresa
      cnpj: json['EmpresaCNPJ'],
    );
  }

  Map<String, dynamic> toJson(String senha) {
    return {
      'UsuarioNome': nome,
      'UsuarioTelefone': telefone,
      'UsuarioEmail': email,
      'UsuarioSenha': senha,
      'UsuarioTipo': tipo,
    };
  }

  Map<String, dynamic> toJsonCompleto() {
    return {
      'UsuarioId': id,
      'UsuarioNome': nome,
      'UsuarioTelefone': telefone,
      'UsuarioEmail': email,
      'UsuarioTipo': tipo,
    };
  }

  // Método para criar uma cópia do usuário (útil para updates)
  Usuario copyWith({
    int? id,
    String? nome,
    String? telefone,
    String? email,
    String? tipo,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      tipo: tipo ?? this.tipo,
    );
  }

  // Método para converter para JSON string (para salvar no SharedPreferences)
  String toJsonString() {
    return '''
    {
      "UsuarioId": ${id ?? 0},
      "UsuarioNome": "$nome",
      "UsuarioTelefone": "$telefone",
      "UsuarioEmail": "$email",
      "UsuarioTipo": "$tipo"
    }
    ''';
  }

  // Factory para criar de JSON string
  factory Usuario.fromJsonString(String jsonString) {

    // Extrair valores manualmente (ou usar json.decode)
    final idMatch = RegExp(r'"UsuarioId": (\d+)').firstMatch(jsonString);
    final nomeMatch = RegExp(
      r'"UsuarioNome": "([^"]+)"',
    ).firstMatch(jsonString);
    final telefoneMatch = RegExp(
      r'"UsuarioTelefone": "([^"]+)"',
    ).firstMatch(jsonString);
    final emailMatch = RegExp(
      r'"UsuarioEmail": "([^"]+)"',
    ).firstMatch(jsonString);
    final tipoMatch = RegExp(
      r'"UsuarioTipo": "([^"]+)"',
    ).firstMatch(jsonString);

    return Usuario(
      id: idMatch != null ? int.parse(idMatch.group(1)!) : null,
      nome: nomeMatch?.group(1) ?? '',
      telefone: telefoneMatch?.group(1) ?? '',
      email: emailMatch?.group(1) ?? '',
      tipo: tipoMatch?.group(1) ?? '',
    );
  }

  @override
  String toString() {
    return 'Usuario(id: $id, nome: $nome, email: $email, tipo: $tipo)';
  }
}
