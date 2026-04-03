import 'package:flutter/material.dart';
import '../models/modUser.dart';

class UsuarioProvider extends ChangeNotifier {
  Usuario? _usuario;
  String? _token;

  Usuario? get usuario => _usuario;
  String? get token => _token;

  void setUsuario(Usuario usuario, String token) {
    _usuario = usuario;
    _token = token;
    notifyListeners();
  }

  void atualizarUsuario(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void logout() {
    _usuario = null;
    _token = null;
    notifyListeners();
  }
  
  // Método para verificar se há usuário logado
  bool get estaLogado => _usuario != null && _token != null;
}