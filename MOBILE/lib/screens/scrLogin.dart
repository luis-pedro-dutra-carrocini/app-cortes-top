import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cortes_top/services/serApi.dart';
import 'package:provider/provider.dart';
import '../services/serAuth.dart';
import '../services/serAuthSocial.dart';
import '../models/modUser.dart';
import '../providers/proUser.dart';
import 'scrUserRegister.dart';
import 'scrHome.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final SocialAuthService _socialAuthService = SocialAuthService();

  // Controladores dos campos de texto
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  String _tipoUsuario = 'CLIENTE';

  bool _isLoading = false;
  bool _obscureSenha = true;
  //bool _lembrarUsuario = false;
  bool _mostrarSelecaoTipo = true;

  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Widget _buildTipoUsuarioRadio({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipoUsuario = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: _tipoUsuario == value
              ? const Color(0xFF4A5C6B).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: _tipoUsuario == value
                  ? const Color(0xFF4A5C6B)
                  : Colors.grey,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _tipoUsuario == value
                      ? const Color(0xFF4A5C6B)
                      : Colors.grey,
                  fontWeight: _tipoUsuario == value
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Radio<String>(
              value: value,
              groupValue: _tipoUsuario,
              onChanged: (newValue) {
                setState(() {
                  _tipoUsuario = newValue!;
                });
              },
              activeColor: const Color(0xFF4A5C6B),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  // Widget para as opções de rádio no modal
  Widget _buildModalTipoRadio({
    required String value,
    required String label,
    required IconData icon,
    required String? selectedValue,
    required Function(String) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selectedValue == value
              ? const Color(0xFF4A5C6B).withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedValue == value
                ? const Color(0xFF4A5C6B)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selectedValue == value
                  ? const Color(0xFF4A5C6B)
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selectedValue == value
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: selectedValue == value
                      ? const Color(0xFF4A5C6B)
                      : Colors.black87,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: selectedValue,
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              activeColor: const Color(0xFF4A5C6B),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.login(
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        tipo: _tipoUsuario, // <-- NOVO PARÂMETRO
      );

      if (mounted) {
        if (result['success']) {
          final usuario = result['usuario'] as Usuario;
          final token = result['token'] as String;

          await _authService.logout();
          await _authService.saveUserData(token, usuario);

          final usuarioProvider = Provider.of<UsuarioProvider>(
            context,
            listen: false,
          );
          usuarioProvider.setUsuario(usuario, token);

          _mostrarDialogSucesso(usuario, token);
        } else {
          _mostrarDialogErro(result['message']);
        }
      }
    } catch (e) {
      //print('Erro detalhado: $e');
      if (mounted) {
        _mostrarDialogErro('Erro ao fazer login: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Método modificado para iniciar o processo de login com Google
  Future<void> _loginWithGoogle() async {
    // Primeiro mostra o modal para selecionar o tipo
    await _mostrarModalSelecionarTipo();
  }

  // Novo método para continuar com o login após selecionar o tipo
  Future<void> _continuarLoginComGoogle(String tipoUsuario) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obter token do Google
      final googleResult = await _socialAuthService.loginWithGoogle();

      if (!googleResult['success']) {
        if (mounted) {
          _mostrarDialogErro(googleResult['error']);
        }
        return;
      }

      // Enviar token para o backend com o tipo selecionado
      final result = await _apiService.loginWithGoogle(
        googleToken: googleResult['token'],
        tipo: tipoUsuario, // Usando o tipo selecionado no modal
        tipoRequisicao: 'LOGIN',
      );

      if (mounted) {
        if (result['success']) {
          final usuario = result['usuario'] as Usuario;
          final token = result['token'] as String;

          await _authService.saveUserData(token, usuario);

          final usuarioProvider = Provider.of<UsuarioProvider>(
            context,
            listen: false,
          );
          usuarioProvider.setUsuario(usuario, token);

          _mostrarDialogSucesso(usuario, token);
        } else {
          _mostrarDialogErro(result['message']);
        }
      }
    } catch (e) {
      print('Erro no login com Google: $e');
      if (mounted) {
        _mostrarDialogErro('Erro ao fazer login com Google: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Adicione este método para mostrar o modal de seleção de tipo
  Future<void> _mostrarModalSelecionarTipo() async {
    String? tipoSelecionado;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Selecionar Tipo de Acesso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5C6B),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Como você deseja acessar o sistema?',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  // Opção Cliente
                  _buildModalTipoRadio(
                    value: 'CLIENTE',
                    label: 'Cliente',
                    icon: Icons.person,
                    selectedValue: tipoSelecionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        tipoSelecionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Opção Prestador
                  _buildModalTipoRadio(
                    value: 'PRESTADOR',
                    label: 'Prestador',
                    icon: Icons.work_outline,
                    selectedValue: tipoSelecionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        tipoSelecionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Opção Empresa
                  _buildModalTipoRadio(
                    value: 'EMPRESA',
                    label: 'Empresa',
                    icon: Icons.business,
                    selectedValue: tipoSelecionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        tipoSelecionado = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: tipoSelecionado == null
                      ? null
                      : () {
                          Navigator.pop(context, tipoSelecionado);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5C6B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    ).then((selectedType) async {
      if (selectedType != null) {
        // Se o usuário selecionou um tipo, continua com o login do Google
        await _continuarLoginComGoogle(selectedType);
      }
    });
  }

  /*
  Future<void> _loginWithApple() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obter token da Apple
      final appleResult = await _socialAuthService.loginWithApple();

      if (!appleResult['success']) {
        if (mounted) {
          _mostrarDialogErro(appleResult['error']);
        }
        return;
      }

      // Para Apple, você precisará de um endpoint similar no backend
      // ou pode reutilizar o mesmo endpoint do Google
      final result = await _apiService.loginWithGoogle(
        googleToken: appleResult['token'], // Adaptar para token da Apple
        tipo: _tipoUsuario,
      );

      if (mounted) {
        if (result['success']) {
          final usuario = result['usuario'] as Usuario;
          final token = result['token'] as String;

          await _authService.saveUserData(token, usuario);

          final usuarioProvider = Provider.of<UsuarioProvider>(
            context,
            listen: false,
          );
          usuarioProvider.setUsuario(usuario, token);

          _mostrarDialogSucesso(usuario, token);
        } else {
          _mostrarDialogErro(result['message']);
        }
      }
    } catch (e) {
      print('Erro no login com Apple: $e');
      if (mounted) {
        _mostrarDialogErro('Erro ao fazer login com Apple: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  */

  void _mostrarDialogSucesso(Usuario usuario, String token) {
    // Salvar dados antes de navegar
    _authService.saveUserData(token, usuario);

    // Adicionado parâmetro token
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bem-vindo!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Olá, ${usuario.nome}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fechar dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    usuario: usuario,
                    token: token, // Usando o token
                  ),
                ),
              );
            },
            child: const Text(
              'Continuar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogErro(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.error_outline, color: Colors.red, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Erro no Login',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(mensagem, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tentar novamente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho com logo/ilustração
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(top: 20, bottom: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A5C6B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.login,
                          size: 50,
                          color: Color(0xFF4A5C6B),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Bem-vindo de volta!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A5C6B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Faça login para continuar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Campo E-mail
                _buildTextField(
                  controller: _emailController,
                  label: 'E-mail',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'E-mail é obrigatório';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo Senha
                _buildTextField(
                  controller: _senhaController,
                  label: 'Senha',
                  icon: Icons.lock_outline,
                  obscureText: _obscureSenha,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureSenha
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureSenha = !_obscureSenha;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Senha é obrigatória';
                    }
                    if (value.length < 6) {
                      return 'Senha deve ter no mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Seleção de tipo de usuário (inicialmente visível)
                if (_mostrarSelecaoTipo) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Entrar como:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A5C6B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTipoUsuarioRadio(
                                value: 'CLIENTE',
                                label: 'Cliente',
                                icon: Icons.person,
                              ),
                            ),
                            Expanded(
                              child: _buildTipoUsuarioRadio(
                                value: 'PRESTADOR',
                                label: 'Prestador',
                                icon: Icons.work_outline,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTipoUsuarioRadio(
                                value: 'EMPRESA',
                                label: 'Empresa',
                                icon: Icons.business,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Opções adicionais
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Link "Esqueceu a senha?"
                    TextButton(
                      onPressed: () {
                        // TODO: Implementar recuperação de senha
                      },
                      child: const Text(
                        'Esqueceu a senha?',
                        style: TextStyle(
                          color: Color(0xFF4A5C6B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Botão Login
                ElevatedButton(
                  onPressed: _isLoading ? null : _fazerLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5C6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 30),

                // Divisor "ou"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),

                const SizedBox(height: 30),

                // Opções de login social (opcional)
                // Botão Google
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: Image.asset(
                    'assets/google_logo.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  label: const Text(
                    'Continuar com Google',
                    style: TextStyle(color: Colors.black87),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Botão Apple
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implementar login com Apple
                  },
                  icon: const Icon(Icons.apple, color: Colors.black),
                  label: const Text(
                    'Continuar com Apple',
                    style: TextStyle(color: Colors.black87),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Link para cadastro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem uma conta? ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CadastroScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Cadastre-se',
                        style: TextStyle(
                          color: Color(0xFF4A5C6B),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF4A5C6B)),
        prefixIcon: Icon(icon, color: const Color(0xFF4A5C6B)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A5C6B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
