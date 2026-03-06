import 'modUser.dart'; // Importe o modelo unificado

class LoginResponse {
  final String message;
  final String token;
  final Usuario usuario;

  LoginResponse({
    required this.message,
    required this.token,
    required this.usuario,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      usuario: Usuario.fromJson(json['usuario']),
    );
  }
}