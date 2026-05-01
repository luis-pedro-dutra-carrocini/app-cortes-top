import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cortes_top/services/serApi.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../services/serAuthSocial.dart';
import '../services/serAuth.dart';
import '../providers/proUser.dart';
import '../models/modUser.dart';
import 'scrHome.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  // Controladores dos campos de texto
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // Controladores de endereço
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _cepController = TextEditingController();

  final _cnpjController = TextEditingController();

  final SocialAuthService _socialAuthService = SocialAuthService();
  final AuthService _authService = AuthService();

  // Máscaras
  final _telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##', // A máscara visual permanece a mesma
    filter: {"#": RegExp(r'[A-Za-z0-9]')}, // AGORA ACEITA LETRAS E NÚMEROS
  );

  String _tipoUsuario = 'CLIENTE'; // Valor padrão
  bool _isLoading = false;
  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;
  bool _mostrarEndereco = false; // Controla se mostra campos de endereço
  bool _mostrarCNPJ = false; // Controla se mostra campo CNPJ

  bool _consultandoCep = false;
  bool _cepConsultado = false;
  String? _ultimoCepConsultado;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _atualizarVisibilidadeEndereco();
  }

  void _atualizarVisibilidadeEndereco() {
    setState(() {
      _mostrarEndereco = _tipoUsuario == 'PRESTADOR';
      _mostrarCNPJ = _tipoUsuario == 'EMPRESA'; // Nova variável
    });
  }

  @override
  void dispose() {
    // Limpar controladores
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    _cepController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _consultarCep() async {
    String cepNumerico = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cepNumerico.length != 8) {
      _mostrarSnackBar(
        'CEP inválido. Digite um CEP com 8 números.',
        Colors.orange,
      );
      return;
    }

    // Não consultar novamente o mesmo CEP
    if (_ultimoCepConsultado == cepNumerico) {
      return;
    }

    setState(() {
      _consultandoCep = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepNumerico/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('erro')) {
          _mostrarSnackBar('CEP não encontrado.', Colors.red);
          _limparCamposEndereco(excetoCep: true);
          setState(() {
            _cepConsultado = false;
            _ultimoCepConsultado = null;
          });
        } else {
          setState(() {
            _ruaController.text = data['logradouro'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _cidadeController.text = data['localidade'] ?? '';
            _estadoController.text = data['uf'] ?? '';
            // Complemento pode vir da API, mas não sobrescreve se usuário já digitou
            if (_complementoController.text.isEmpty) {
              _complementoController.text = data['complemento'] ?? '';
            }
            _cepConsultado = true;
            _ultimoCepConsultado = cepNumerico;
          });
          _mostrarSnackBar('CEP encontrado!', Colors.green);
        }
      } else {
        _mostrarSnackBar('Erro ao consultar CEP. Tente novamente.', Colors.red);
      }
    } catch (e) {
      _mostrarSnackBar('Erro de conexão ao consultar CEP.', Colors.red);
    } finally {
      setState(() {
        _consultandoCep = false;
      });
    }
  }

  // Modifique o método _loginWithGoogle para mostrar o modal primeiro
  Future<void> _loginWithGoogle() async {
    // Primeiro mostra o modal para selecionar o tipo
    await _mostrarModalSelecionarTipoCadastro();
  }

  // Novo método para continuar com o cadastro após selecionar o tipo
  Future<void> _continuarCadastroComGoogle(String tipoUsuario) async {
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
        tipoRequisicao: 'CADASTRO', // Mantém CADASTRO para registro
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

          _mostrarDialogSucessoSocial(usuario, token);
        } else {
          _mostrarDialogErro(result['message']);
        }
      }
    } catch (e) {
      print('Erro no cadastro com Google: $e');
      if (mounted) {
        _mostrarDialogErro(
          'Erro ao fazer cadastro com Google: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cadastrar() async {
    // Validar formulário
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validação adicional para prestador: garantir que campos obrigatórios não estão vazios
    if (_tipoUsuario == 'PRESTADOR') {
      if (_ruaController.text.trim().isEmpty) {
        _mostrarSnackBar('Rua é obrigatória', Colors.orange);
        return;
      }
      if (_numeroController.text.trim().isEmpty) {
        _mostrarSnackBar('Número é obrigatório', Colors.orange);
        return;
      }
      if (_bairroController.text.trim().isEmpty) {
        _mostrarSnackBar('Bairro é obrigatório', Colors.orange);
        return;
      }
      if (_cidadeController.text.trim().isEmpty) {
        _mostrarSnackBar('Cidade é obrigatória', Colors.orange);
        return;
      }
      if (_estadoController.text.trim().isEmpty) {
        _mostrarSnackBar('Estado é obrigatório', Colors.orange);
        return;
      }
      if (_cepController.text.trim().isEmpty) {
        _mostrarSnackBar('CEP é obrigatório', Colors.orange);
        return;
      }
    }

    // No método _cadastrar, dentro da validação para EMPRESA:
    if (_tipoUsuario == 'EMPRESA') {
      if (_cnpjController.text.trim().isEmpty) {
        _mostrarSnackBar('CNPJ é obrigatório para empresa', Colors.orange);
        return;
      }

      // Remover máscara para verificar
      String cnpjLimpo = _cnpjController.text.replaceAll(
        RegExp(r'[^A-Za-z0-9]'),
        '',
      );

      // Validar tamanho (14 caracteres)
      if (cnpjLimpo.length != 14) {
        _mostrarSnackBar('CNPJ deve ter 14 caracteres', Colors.orange);
        return;
      }

      // Validar últimos 2 dígitos (devem ser numéricos - dígitos verificadores)
      String dv = cnpjLimpo.substring(12);
      if (!RegExp(r'^[0-9]{2}$').hasMatch(dv)) {
        _mostrarSnackBar(
          'Os dois últimos dígitos do CNPJ devem ser números',
          Colors.orange,
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar dados base com campos LIMPOS (sem máscara)
      final Map<String, dynamic> dados = {
        'nome': _nomeController.text.trim(),
        // IMPORTANTE: Remover máscara do telefone
        'telefone': _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        'email': _emailController.text.trim().toLowerCase(),
        'senha': _senhaController.text,
        'tipo': _tipoUsuario,
      };

      // Adicionar CNPJ se for empresa (SEM máscara e em maiúsculas)
      if (_tipoUsuario == 'EMPRESA') {
        String cnpjLimpo = _cnpjController.text
            .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
            .toUpperCase();
        dados.addAll({'cnpj': cnpjLimpo});
      }

      // Adicionar endereço se for prestador (com campos LIMPOS)
      if (_tipoUsuario == 'PRESTADOR') {
        dados.addAll({
          'rua': _ruaController.text.trim(),
          'numero': _numeroController.text.trim(),
          'complemento': _complementoController.text.trim().isEmpty
              ? null
              : _complementoController.text.trim(),
          'bairro': _bairroController.text.trim(),
          'cidade': _cidadeController.text.trim(),
          'estado': _estadoController.text.trim().isNotEmpty
              ? _estadoController.text.trim().toUpperCase()
              : '',
          // IMPORTANTE: Remover máscara do CEP
          'cep': _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        });
      }

      //print('Dados a serem enviados: $dados'); // Log para debug

      final result = await _apiService.cadastrarUsuario(dados);

      if (result['success']) {
        _mostrarDialogSucesso(result['message']);
      } else {
        _mostrarDialogErro(result['message']);
      }
    } catch (e) {
      //print('Erro no cadastro: $e'); // Log para debug
      _mostrarDialogErro('Erro inesperado: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Adicione este método para mostrar o modal de seleção de tipo no cadastro
  Future<void> _mostrarModalSelecionarTipoCadastro() async {
    String? tipoSelecionado;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Selecionar Tipo de Cadastro',
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
                    'Como você deseja se cadastrar no sistema?',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  // Opção Cliente
                  _buildModalTipoRadioCadastro(
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
                  _buildModalTipoRadioCadastro(
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
                  _buildModalTipoRadioCadastro(
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
        // Se o usuário selecionou um tipo, continua com o cadastro do Google
        await _continuarCadastroComGoogle(selectedType);
      }
    });
  }

  // Widget para as opções de rádio no modal de cadastro
  Widget _buildModalTipoRadioCadastro({
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

  void _limparCamposEndereco({bool excetoCep = false}) {
    setState(() {
      if (!excetoCep) _cepController.clear();
      _ruaController.clear();
      _bairroController.clear();
      _cidadeController.clear();
      _estadoController.clear();
      _numeroController.clear();
      _complementoController.clear();
      _cepConsultado = false;
      _ultimoCepConsultado = null;
    });
  }

  void _mostrarDialogSucesso(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sucesso!'),
        content: Text(mensagem),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fechar dialog
              Navigator.pop(context); // Voltar para tela anterior
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF4A5C6B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogSucessoSocial(Usuario usuario, String token) {
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
        title: const Text('Erro'),
        content: Text(mensagem),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF4A5C6B),
                fontWeight: FontWeight.bold,
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
                // Ícone ou ilustração
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8EEF2),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1,
                    size: 50,
                    color: Color(0xFF4A5C6B),
                  ),
                ),

                Container(
                  margin: const EdgeInsets.only(top: 5, bottom: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Cadastre-se já!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A5C6B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Faça cadastro para entrar na plataforma.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Campo Nome
                _buildTextField(
                  controller: _nomeController,
                  label: 'Nome completo',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo Telefone
                _buildTextField(
                  controller: _telefoneController,
                  label: 'Telefone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_telefoneMask],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Telefone é obrigatório';
                    }
                    // Remover máscara para validar
                    String numeros = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (numeros.length != 11) {
                      return 'Telefone deve ter 11 dígitos (incluindo DDD)';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo Email
                _buildTextField(
                  controller: _emailController,
                  label: 'E-mail',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-mail é obrigatório';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
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

                // Campo Confirmar Senha
                _buildTextField(
                  controller: _confirmarSenhaController,
                  label: 'Confirmar senha',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirmarSenha,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmarSenha
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmarSenha = !_obscureConfirmarSenha;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirme sua senha';
                    }
                    if (value != _senhaController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Tipo de Usuário
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
                        'Tipo de usuário',
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

                // Campo CNPJ (visível apenas para EMPRESA)
                if (_mostrarCNPJ) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              color: const Color(0xFF4A5C6B),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Dados da Empresa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A5C6B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Campo CNPJ
                        _buildTextField(
                          controller: _cnpjController,
                          label: 'CNPJ',
                          icon: Icons.qr_code,
                          keyboardType:
                              TextInputType.text, // Mudar de number para text
                          textCapitalization: TextCapitalization
                              .characters, // Converter para maiúsculas
                          inputFormatters: [_cnpjMask],
                          validator: (value) {
                            if (_tipoUsuario == 'EMPRESA') {
                              if (value == null || value.isEmpty) {
                                return 'CNPJ é obrigatório';
                              }
                              // A validação será feita no _cadastrar
                            }
                            return null;
                          },
                          // Hint explicativo
                          hintText: 'Digite o CNPJ',
                        ),
                      ],
                    ),
                  ),
                ],

                // Campos de endereço (visível apenas para PRESTADOR)
                if (_mostrarEndereco) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: const Color(0xFF4A5C6B),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Endereço (obrigatório)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A5C6B),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildTextField(
                                controller: _cepController,
                                label: 'CEP',
                                icon: Icons.markunread_mailbox,
                                keyboardType: TextInputType.number,
                                inputFormatters: [_cepMask],
                                onChanged: (value) {
                                  // Quando o CEP for alterado, limpar o status de consultado
                                  if (_cepConsultado) {
                                    setState(() {
                                      _cepConsultado = false;
                                      _ultimoCepConsultado = null;
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (_tipoUsuario == 'PRESTADOR' &&
                                      (value == null || value.isEmpty)) {
                                    return 'CEP é obrigatório';
                                  }
                                  if (value != null && value.isNotEmpty) {
                                    String numeros = value.replaceAll(
                                      RegExp(r'[^0-9]'),
                                      '',
                                    );
                                    if (numeros.length != 8) {
                                      return 'CEP deve ter 8 números';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: _consultandoCep
                                  ? Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F7FA),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF4A5C6B),
                                          ),
                                        ),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _consultarCep,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4A5C6B,
                                        ),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(0, 56),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.search,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Cidade e Estado
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _cidadeController,
                                label: 'Cidade',
                                icon: Icons.location_city,
                                readOnly: _cepConsultado, // <-- ADICIONAR
                                validator: (value) {
                                  if (_tipoUsuario == 'PRESTADOR' &&
                                      (value == null || value.isEmpty)) {
                                    return 'Cidade é obrigatória';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: _buildTextField(
                                controller: _estadoController,
                                label: 'UF',
                                icon: Icons.pin,
                                maxLength: 2,
                                readOnly: _cepConsultado, // <-- ADICIONAR
                                textCapitalization:
                                    TextCapitalization.characters,
                                validator: (value) {
                                  if (_tipoUsuario == 'PRESTADOR' &&
                                      (value == null || value.isEmpty)) {
                                    return 'UF é obrigatório';
                                  }
                                  if (value != null && value.length != 2) {
                                    return 'Use 2 letras';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Bairro
                        _buildTextField(
                          controller: _bairroController,
                          label: 'Bairro',
                          icon: Icons.map,
                          readOnly: _cepConsultado, // <-- ADICIONAR
                          validator: (value) {
                            if (_tipoUsuario == 'PRESTADOR' &&
                                (value == null || value.isEmpty)) {
                              return 'Bairro é obrigatório';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // Rua
                        _buildTextField(
                          controller: _ruaController,
                          label: 'Rua',
                          icon: Icons.streetview,
                          readOnly: _cepConsultado, // <-- ADICIONAR
                          validator: (value) {
                            if (_tipoUsuario == 'PRESTADOR' &&
                                (value == null || value.isEmpty)) {
                              return 'Rua é obrigatória';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _numeroController,
                          label: 'Número',
                          icon: Icons.numbers,
                          validator: (value) {
                            if (_tipoUsuario == 'PRESTADOR' &&
                                (value == null || value.isEmpty)) {
                              return 'Número é obrigatório';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _complementoController,
                          label: 'Complemento',
                          icon: Icons.add_home,
                          validator: null, // Opcional
                        ),

                        if (_cepConsultado) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              _limparCamposEndereco(excetoCep: false);
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Buscar outro CEP'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4A5C6B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Botão Cadastrar
                ElevatedButton(
                  onPressed: _isLoading ? null : _cadastrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A5C6B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
                          'Cadastrar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

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
                    'Cadastrar-se com Google',
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
                    'Cadastrar-se com Apple',
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

                // Link para login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já tem uma conta? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Faça login',
                        style: TextStyle(
                          color: Color(0xFF4A5C6B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false, // <-- NOVO PARÂMETRO
    Function(String)? onChanged, // <-- NOVO PARÂMETRO
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      readOnly: readOnly, // <-- APLICAR
      onChanged: onChanged, // <-- APLICAR
      decoration: InputDecoration(
        hintText: hintText,
        labelText: label,
        labelStyle: TextStyle(
          color: readOnly
              ? Colors.grey
              : const Color(0xFF4A5C6B), // Cor diferente quando readonly
        ),
        prefixIcon: Icon(
          icon,
          color: readOnly
              ? Colors.grey
              : const Color(0xFF4A5C6B), // Ícone cinza quando readonly
        ),
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
          borderSide: readOnly
              ? BorderSide(color: Colors.grey.shade400)
              : const BorderSide(color: Color(0xFF4A5C6B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        filled: true,
        fillColor: readOnly
            ? const Color(0xFFEEEEEE) // Fundo mais claro quando readonly
            : const Color(0xFFF5F7FA),
        counterText: '',
      ),
    );
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
          _atualizarVisibilidadeEndereco();
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
                  _atualizarVisibilidadeEndereco();
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
}
