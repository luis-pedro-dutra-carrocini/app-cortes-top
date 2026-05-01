// ignore_for_file: duplicate_ignore, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../models/modUser.dart';
import '../services/serUser.dart';
import '../services/serAuth.dart';
import '../providers/proUser.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PerfilScreen extends StatefulWidget {
  final Usuario usuario;
  final String token;

  const PerfilScreen({super.key, required this.usuario, required this.token});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late Usuario _usuario;
  late String _token;

  // Controladores
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // Controladores para endereço (PRESTADOR)
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  // Controlador para CNPJ (EMPRESA)
  final _cnpjController = TextEditingController();

  // Máscaras
  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {"#": RegExp(r'[A-Za-z0-9]')}, // Alfanumérico para novo formato
  );

  String _formatarTelefone(String telefone) {
    String numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length == 11) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    } else if (numeros.length == 10) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    }
    return telefone;
  }

  String _formatarCEP(String cep) {
    String numeros = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length == 8) {
      return '${numeros.substring(0, 5)}-${numeros.substring(5)}';
    }
    return cep;
  }

  String _formatarCNPJ(String cnpj) {
    if (cnpj.isEmpty) return 'CNPJ não cadastrado';
    String limpo = cnpj.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (limpo.length == 14) {
      return '${limpo.substring(0, 2)}.${limpo.substring(2, 5)}.${limpo.substring(5, 8)}/${limpo.substring(8, 12)}-${limpo.substring(12)}';
    }
    return cnpj;
  }

  // Controle de consulta de CEP
  bool _consultandoCep = false;
  bool _cepConsultado = false;
  String? _ultimoCepConsultado;

  // Máscara para telefone
  final _telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  bool _isLoading = false;
  bool _isEditing = false;
  bool _obscureSenha = true;
  bool _obscureConfirmarSenha = true;
  bool _confirmarExclusao = false;

  final UsuarioService _usuarioService = UsuarioService();
  final AuthService _authService = AuthService();

  // Variáveis para controle de validação em tempo real
  bool _telefoneValido = true;
  bool _cnpjValido = true;
  bool _enderecoValido = true;

  bool _mostrarAlertaSempre = true; // Mostrar alerta mesmo sem edição

  // Lista de mensagens de erro para exibir no alerta
  List<String> _mensagensAlerta = [];

  void _validarCamposEmTempoReal() {
    List<String> mensagens = [];

    // Validar telefone (obrigatório para todos os tipos)
    String telefone = _telefoneController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    bool telefoneOk = telefone.length >= 10 && telefone.length <= 11;

    if (!telefoneOk && telefone.isNotEmpty) {
      mensagens.add('• Telefone deve ter 10 ou 11 dígitos (incluindo DDD)');
    } else if (telefone.isEmpty) {
      mensagens.add('• Telefone é obrigatório');
    }

    // Validações específicas por tipo
    if (_usuario.tipo == 'CLIENTE') {
      // Cliente: apenas telefone é obrigatório
      _telefoneValido = telefoneOk && telefone.isNotEmpty;
    } else if (_usuario.tipo == 'PRESTADOR') {
      // Prestador: telefone + endereço completo
      String cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
      bool cepOk = cep.length == 8;

      // Obter valores dos controllers corretamente
      String rua = _ruaController.text.trim();
      String numero = _numeroController.text.trim();
      String bairro = _bairroController.text.trim();
      String cidade = _cidadeController.text.trim();
      String estado = _estadoController.text.trim();

      bool ruaOk = rua.isNotEmpty;
      bool numeroOk = numero.isNotEmpty;
      bool bairroOk = bairro.isNotEmpty;
      bool cidadeOk = cidade.isNotEmpty;
      bool estadoOk = estado.length == 2;

      _telefoneValido = telefoneOk && telefone.isNotEmpty;
      _enderecoValido =
          cepOk && ruaOk && numeroOk && bairroOk && cidadeOk && estadoOk;

      if (telefone.isEmpty) {
        mensagens.add('• Telefone é obrigatório');
      } else if (!telefoneOk) {
        mensagens.add('• Telefone deve ter 10 ou 11 dígitos (incluindo DDD)');
      }

      if (cep.isEmpty) {
        mensagens.add('• CEP é obrigatório');
      } else if (!cepOk) {
        mensagens.add('• CEP inválido (deve ter 8 números)');
      }

      if (rua.isEmpty) {
        mensagens.add('• Rua é obrigatória');
      }
      if (numero.isEmpty) {
        mensagens.add('• Número é obrigatório');
      }
      if (bairro.isEmpty) {
        mensagens.add('• Bairro é obrigatório');
      }
      if (cidade.isEmpty) {
        mensagens.add('• Cidade é obrigatória');
      }
      if (estado.isEmpty) {
        mensagens.add('• Estado é obrigatório (2 letras)');
      } else if (!estadoOk) {
        mensagens.add('• Estado deve ter 2 letras');
      }
    } else if (_usuario.tipo == 'EMPRESA') {
      // Empresa: telefone + CNPJ
      String cnpj = _cnpjController.text.replaceAll(
        RegExp(r'[^A-Za-z0-9]'),
        '',
      );
      bool cnpjOk = cnpj.length == 14;

      _telefoneValido = telefoneOk && telefone.isNotEmpty;
      _cnpjValido = cnpjOk;

      if (telefone.isEmpty) {
        mensagens.add('• Telefone é obrigatório');
      } else if (!telefoneOk) {
        mensagens.add('• Telefone deve ter 10 ou 11 dígitos (incluindo DDD)');
      }

      if (cnpj.isEmpty) {
        mensagens.add('• CNPJ é obrigatório');
      } else if (!cnpjOk) {
        mensagens.add('• CNPJ deve ter 14 caracteres');
      }
    }

    setState(() {
      _mensagensAlerta = mensagens;
    });
  }

  // Método para verificar se o botão salvar deve ser habilitado
  bool _isFormValido() {
    String telefone = _telefoneController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    bool telefoneOk =
        telefone.length >= 10 && telefone.length <= 11 && telefone.isNotEmpty;

    if (!telefoneOk) return false;

    if (_usuario.tipo == 'PRESTADOR') {
      String cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
      return cep.length == 8 &&
          cep.isNotEmpty &&
          _ruaController.text.trim().isNotEmpty &&
          _numeroController.text.trim().isNotEmpty &&
          _bairroController.text.trim().isNotEmpty &&
          _cidadeController.text.trim().isNotEmpty &&
          _estadoController.text.length == 2;
    } else if (_usuario.tipo == 'EMPRESA') {
      String cnpj = _cnpjController.text.replaceAll(
        RegExp(r'[^A-Za-z0-9]'),
        '',
      );
      return cnpj.length == 14 && cnpj.isNotEmpty;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _token = widget.token;
    _preencherCampos();
    _adicionarListeners();

    // Validar campos imediatamente ao carregar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validarCamposEmTempoReal();
    });
  }

  void _adicionarListeners() {
    // Adicionar listeners para validação em tempo real
    _telefoneController.addListener(_validarCamposEmTempoReal);

    if (_usuario.tipo == 'PRESTADOR') {
      _cepController.addListener(_validarCamposEmTempoReal);
      _ruaController.addListener(_validarCamposEmTempoReal);
      _numeroController.addListener(_validarCamposEmTempoReal);
      _bairroController.addListener(_validarCamposEmTempoReal);
      _cidadeController.addListener(_validarCamposEmTempoReal);
      _estadoController.addListener(_validarCamposEmTempoReal);
    } else if (_usuario.tipo == 'EMPRESA') {
      _cnpjController.addListener(_validarCamposEmTempoReal);
    }
  }

  void _preencherCampos() {
    _nomeController.text = _usuario.nome;
    _telefoneController.text = _usuario.telefone;
    _emailController.text = _usuario.email;

    // Preencher campos específicos
    if (_usuario.tipo == 'PRESTADOR') {
      _cepController.text = _usuario.cep ?? '';
      _ruaController.text = _usuario.rua ?? '';
      _numeroController.text = _usuario.numero ?? '';
      _complementoController.text = _usuario.complemento ?? '';
      _bairroController.text = _usuario.bairro ?? '';
      _cidadeController.text = _usuario.cidade ?? '';
      _estadoController.text = _usuario.estado ?? '';
    } else if (_usuario.tipo == 'EMPRESA') {
      _cnpjController.text = _usuario.cnpj ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();

    // Remover listeners
    _telefoneController.removeListener(_validarCamposEmTempoReal);

    if (_usuario.tipo == 'PRESTADOR') {
      _cepController.removeListener(_validarCamposEmTempoReal);
      _ruaController.removeListener(_validarCamposEmTempoReal);
      _numeroController.removeListener(_validarCamposEmTempoReal);
      _bairroController.removeListener(_validarCamposEmTempoReal);
      _cidadeController.removeListener(_validarCamposEmTempoReal);
      _estadoController.removeListener(_validarCamposEmTempoReal);
    } else if (_usuario.tipo == 'EMPRESA') {
      _cnpjController.removeListener(_validarCamposEmTempoReal);
    }

    super.dispose();
  }

  String _limparTelefone(String telefoneFormatado) {
    return telefoneFormatado.replaceAll(RegExp(r'[^0-9]'), '');
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
            if (_complementoController.text.isEmpty) {
              _complementoController.text = data['complemento'] ?? '';
            }
            _cepConsultado = true;
            _ultimoCepConsultado = cepNumerico;
          });
          _mostrarSnackBar('CEP encontrado!', Colors.green);
        }
      } else {
        _mostrarSnackBar('Erro ao consultar CEP.', Colors.red);
      }
    } catch (e) {
      _mostrarSnackBar('Erro de conexão ao consultar CEP.', Colors.red);
    } finally {
      setState(() {
        _consultandoCep = false;
      });
    }
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

  Future<void> _salvarAlteracoes() async {
    // Validar novamente antes de salvar
    if (!_isFormValido()) {
      _mostrarSnackBar(
        'Preencha todos os campos obrigatórios corretamente',
        Colors.orange,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validações específicas por tipo
    if (_usuario.tipo == 'PRESTADOR') {
      if (_cepController.text.isEmpty) {
        _mostrarSnackBar('CEP é obrigatório', Colors.orange);
        return;
      }
      if (_ruaController.text.isEmpty) {
        _mostrarSnackBar('Rua é obrigatória', Colors.orange);
        return;
      }
      if (_numeroController.text.isEmpty) {
        _mostrarSnackBar('Número é obrigatório', Colors.orange);
        return;
      }
      if (_bairroController.text.isEmpty) {
        _mostrarSnackBar('Bairro é obrigatório', Colors.orange);
        return;
      }
      if (_cidadeController.text.isEmpty) {
        _mostrarSnackBar('Cidade é obrigatória', Colors.orange);
        return;
      }
      if (_estadoController.text.isEmpty) {
        _mostrarSnackBar('Estado é obrigatório', Colors.orange);
        return;
      }
    } else if (_usuario.tipo == 'EMPRESA') {
      if (_cnpjController.text.isEmpty) {
        _mostrarSnackBar('CNPJ é obrigatório', Colors.orange);
        return;
      }
      String cnpjNumerico = _cnpjController.text.replaceAll(
        RegExp(r'[^A-Za-z0-9]'),
        '',
      );
      if (cnpjNumerico.length != 14) {
        _mostrarSnackBar('CNPJ deve ter 14 caracteres', Colors.orange);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Preparar dados base
      Map<String, dynamic> dados = {
        'nome': _nomeController.text.trim(),
        'telefone': _limparTelefone(_telefoneController.text),
        'email': _emailController.text.trim(),
      };

      if (_senhaController.text.isNotEmpty) {
        dados['senha'] = _senhaController.text;
      }

      // Adicionar dados específicos
      if (_usuario.tipo == 'PRESTADOR') {
        dados.addAll({
          'cep': _cepController.text.trim(),
          'rua': _ruaController.text.trim(),
          'numero': _numeroController.text.trim(),
          'complemento': _complementoController.text.trim().isEmpty
              ? null
              : _complementoController.text.trim(),
          'bairro': _bairroController.text.trim(),
          'cidade': _cidadeController.text.trim(),
          'estado': _estadoController.text.trim().toUpperCase(),
        });
      } else if (_usuario.tipo == 'EMPRESA') {
        dados.addAll({'cnpj': _cnpjController.text.trim()});
      }

      final result = await _usuarioService.atualizarUsuario(
        usuarioId: _usuario.id!,
        token: _token,
        dados: dados,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _usuario = result['data'];
            _isEditing = false;
            _senhaController.clear();
            _confirmarSenhaController.clear();
          });

          await _authService.saveUserData(_token, _usuario);

          final usuarioProvider = Provider.of<UsuarioProvider>(
            context,
            listen: false,
          );
          usuarioProvider.atualizarUsuario(result['data']);

          _mostrarSnackBar('Perfil atualizado com sucesso!', Colors.green);
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro ao atualizar: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _excluirConta() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _usuarioService.excluirUsuario(_usuario.id!, _token);

      if (mounted) {
        if (result['success']) {
          await _authService.logout();

          _mostrarDialogSucessoExclusao();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
          setState(() {
            _confirmarExclusao = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro ao excluir: $e', Colors.red);
      setState(() {
        _confirmarExclusao = false;
        _isLoading = false;
      });
    }
  }

  void _mostrarDialogExclusao() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 50,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Excluir Conta',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              'Tem certeza que deseja excluir sua conta?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Esta ação não poderá ser desfeita.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _excluirConta();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogSucessoExclusao() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Conta Excluída',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text(
              'Sua conta foi excluída com sucesso.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'OK',
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

  void _cancelarEdicao() {
    setState(() {
      _isEditing = false;
      _preencherCampos();
      _senhaController.clear();
      _confirmarSenhaController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, child) {
        final usuario = usuarioProvider.usuario!;

        // Atualizar dados locais se necessário
        if (usuario != _usuario) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _usuario = usuario;
                _preencherCampos();
              });
            }
          });
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A5C6B)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _isEditing ? 'Editar Perfil' : 'Meu Perfil',
              style: const TextStyle(
                color: Color(0xFF4A5C6B),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar
                    Center(
                      child: Container(
                        height: 120,
                        width: 120,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A5C6B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _usuario.tipo == 'PRESTADOR'
                              ? Icons.build
                              : Icons.person,
                          size: 60,
                          color: const Color(0xFF4A5C6B),
                        ),
                      ),
                    ),

                    // Tipo de usuário badge
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 30),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A5C6B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _usuario.tipo == 'PRESTADOR'
                              ? 'Prestador de Serviços'
                              : 'Cliente',
                          style: const TextStyle(
                            color: Color(0xFF4A5C6B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Widget de alerta fixo (somente quando há mensagens)
                    if (_mensagensAlerta.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Atenção! Complete o cadastro com os campos abaixo:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._mensagensAlerta.map(
                                    (mensagem) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        mensagem,
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Campos do formulário
                    _buildTextField(
                      controller: _nomeController,
                      label: 'Nome completo',
                      icon: Icons.person_outline,
                      enabled: _isEditing,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _telefoneController,
                      label: 'Telefone',
                      icon: Icons.phone_outlined,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_telefoneMask],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Telefone é obrigatório';
                        }
                        // Remover máscara para validar
                        String numeros = value.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        if (numeros.length < 10 || numeros.length > 11) {
                          return 'Telefone inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _emailController,
                      label: 'E-mail',
                      icon: Icons.email_outlined,
                      enabled: _usuario.tipoCadastro == 'NORMAL'
                          ? _isEditing
                          : false,
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

                    // Campos específicos para PRESTADOR
                    if (_usuario.tipo == 'PRESTADOR' && _isEditing) ...[
                      const Divider(),
                      const SizedBox(height: 16),

                      // CEP com botão de busca
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              controller: _cepController,
                              label: 'CEP',
                              icon: Icons.markunread_mailbox,
                              enabled: _isEditing,
                              keyboardType: TextInputType.number,
                              inputFormatters: [_cepMask],
                              onChanged: (value) {
                                if (_cepConsultado) {
                                  setState(() {
                                    _cepConsultado = false;
                                    _ultimoCepConsultado = null;
                                  });
                                }
                              },
                              validator: (value) {
                                if (_isEditing &&
                                    (value == null || value.isEmpty)) {
                                  return 'CEP é obrigatório';
                                }
                                if (value != null &&
                                    value
                                            .replaceAll(RegExp(r'[^0-9]'), '')
                                            .length !=
                                        8) {
                                  return 'CEP inválido';
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
                                      backgroundColor: const Color(0xFF4A5C6B),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 56),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
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
                              enabled: _isEditing,
                              readOnly: _cepConsultado,
                              validator: (value) {
                                if (_isEditing &&
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
                              enabled: _isEditing,
                              readOnly: _cepConsultado,
                              maxLength: 2,
                              textCapitalization: TextCapitalization.characters,
                              validator: (value) {
                                if (_isEditing &&
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
                        enabled: _isEditing,
                        readOnly: _cepConsultado,
                        validator: (value) {
                          if (_isEditing && (value == null || value.isEmpty)) {
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
                        enabled: _isEditing,
                        readOnly: _cepConsultado,
                        validator: (value) {
                          if (_isEditing && (value == null || value.isEmpty)) {
                            return 'Rua é obrigatória';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Número e Complemento
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildTextField(
                              controller: _numeroController,
                              label: 'Número',
                              icon: Icons.numbers,
                              enabled: _isEditing,
                              validator: (value) {
                                if (_isEditing &&
                                    (value == null || value.isEmpty)) {
                                  return 'Número é obrigatório';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _complementoController,
                              label: 'Complemento',
                              icon: Icons.add_home,
                              enabled: _isEditing,
                              validator: null,
                            ),
                          ),
                        ],
                      ),

                      if (_cepConsultado) ...[
                        const SizedBox(height: 8),
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

                    // Campo CNPJ para EMPRESA
                    if (_usuario.tipo == 'EMPRESA' && _isEditing) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _cnpjController,
                        label: 'CNPJ',
                        icon: Icons.qr_code,
                        enabled: _isEditing,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [_cnpjMask],
                        hintText: 'Digite o CNPJ',
                        validator: (value) {
                          if (_isEditing) {
                            if (value == null || value.isEmpty) {
                              return 'CNPJ é obrigatório';
                            }
                            String cnpjNumerico = value.replaceAll(
                              RegExp(r'[^A-Za-z0-9]'),
                              '',
                            );
                            if (cnpjNumerico.length != 14) {
                              return 'CNPJ deve ter 14 caracteres';
                            }
                          }
                          return null;
                        },
                      ),
                    ],

                    // Visualização dos dados quando não está editando
                    if (!_isEditing &&
                        _usuario.tipo == 'PRESTADOR' &&
                        _usuario.cep != null) ...[
                      const Divider(),
                      const SizedBox(height: 16),
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
                            const Text(
                              'Endereço cadastrado:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A5C6B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('CEP: ${_formatarCEP(_usuario.cep ?? "")}'),
                            Text(
                              '${_usuario.rua ?? ""}, ${_usuario.numero ?? ""}',
                            ),
                            if (_usuario.complemento != null &&
                                _usuario.complemento!.isNotEmpty)
                              Text('Complemento: ${_usuario.complemento}'),
                            Text(
                              '${_usuario.bairro ?? ""} - ${_usuario.cidade ?? ""}/${_usuario.estado ?? ""}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Telefone: ${_formatarTelefone(_usuario.telefone)}',
                            ), // Adicionado
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!_isEditing &&
                        _usuario.tipo == 'EMPRESA' &&
                        _usuario.cnpj != null) ...[
                      const Divider(),
                      const SizedBox(height: 16),
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
                                const Icon(
                                  Icons.qr_code,
                                  color: Color(0xFF4A5C6B),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'CNPJ:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A5C6B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: Text(
                                _formatarCNPJ(_usuario.cnpj ?? ''),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                    ],

                    if (_isEditing && _usuario.tipoCadastro == 'NORMAL') ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Opção de alterar senha
                      _buildTextField(
                        controller: _senhaController,
                        label: 'Nova senha (opcional)',
                        icon: Icons.lock_outline,
                        enabled: _isEditing,
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
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Senha deve ter no mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _confirmarSenhaController,
                        label: 'Confirmar nova senha',
                        icon: Icons.lock_outline,
                        enabled: _isEditing,
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
                          if (_senhaController.text.isNotEmpty) {
                            if (value == null || value.isEmpty) {
                              return 'Confirme sua nova senha';
                            }
                            if (value != _senhaController.text) {
                              return 'As senhas não coincidem';
                            }
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Botões de ação
                    if (_isEditing) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _cancelarEdicao,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF4A5C6B),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Color(0xFF4A5C6B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_isFormValido())
                                  ? null
                                  : _salvarAlteracoes,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A5C6B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey.shade400,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Salvar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      if (!_isEditing && _mensagensAlerta.isNotEmpty) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text(
                            'Completar Cadastro',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A5C6B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Botão de editar (só aparece quando não está editando)
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF4A5C6B),
                          ),
                          label: const Text(
                            'Editar meu perfil',
                            style: TextStyle(color: Color(0xFF4A5C6B)),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF4A5C6B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 15),

                      // Botão de excluir conta (só aparece quando não está editando)
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _mostrarDialogExclusao,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Excluir minha conta',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool readOnly = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    String? hintText,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(
          color: enabled ? const Color(0xFF4A5C6B) : Colors.grey,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? const Color(0xFF4A5C6B) : Colors.grey,
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
          borderSide: const BorderSide(color: Color(0xFF4A5C6B), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled
            ? (readOnly ? const Color(0xFFEEEEEE) : const Color(0xFFF5F7FA))
            : Colors.grey.shade50,
        counterText: maxLength != null ? '' : null,
      ),
    );
  }
}
