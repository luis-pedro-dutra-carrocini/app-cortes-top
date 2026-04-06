import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/serEstablishment.dart';
import '../../providers/proUser.dart';

class EstabelecimentoFormScreen extends StatefulWidget {
  final Map<String, dynamic>? estabelecimento;

  const EstabelecimentoFormScreen({super.key, this.estabelecimento});

  @override
  State<EstabelecimentoFormScreen> createState() =>
      _EstabelecimentoFormScreenState();
}

class _EstabelecimentoFormScreenState extends State<EstabelecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EstabelecimentoService _service = EstabelecimentoService();

  // Controladores
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();

  // Endereço
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();

  // Máscaras
  final _telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _isLoading = false;
  bool _consultandoCep = false;
  bool _cepConsultado = false;
  String? _ultimoCepConsultado;

  @override
  void initState() {
    super.initState();
    if (widget.estabelecimento != null) {
      _preencherCampos();
    }
  }

  void _preencherCampos() {
    final est = widget.estabelecimento!;

    // Campos básicos
    _nomeController.text = est['nome'] ?? '';

    // Telefone - aplicar máscara
    String telefone = est['telefone'] ?? '';
    if (telefone.length == 11) {
      _telefoneController.text =
          '(${telefone.substring(0, 2)}) ${telefone.substring(2, 7)}-${telefone.substring(7)}';
    } else {
      _telefoneController.text = telefone;
    }

    // Endereço
    String cep = est['cep'] ?? '';
    if (cep.length == 8) {
      _cepController.text = '${cep.substring(0, 5)}-${cep.substring(5)}';
      _cepConsultado = true;
      _ultimoCepConsultado = cep;
    } else {
      _cepController.text = cep;
    }

    _ruaController.text = est['rua'] ?? '';
    _numeroController.text = est['numero'] ?? '';
    _complementoController.text = est['complemento'] ?? '';
    _bairroController.text = est['bairro'] ?? '';
    _cidadeController.text = est['cidade'] ?? '';
    _estadoController.text = est['estado'] ?? '';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _cepController.dispose();
    _ruaController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  Future<void> _consultarCep() async {
    String cepNumerico = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cepNumerico.length != 8) {
      _mostrarSnackBar('CEP inválido. Digite 8 números.', Colors.orange);
      return;
    }

    if (_ultimoCepConsultado == cepNumerico) return;

    setState(() => _consultandoCep = true);

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
      }
    } catch (e) {
      _mostrarSnackBar('Erro ao consultar CEP.', Colors.red);
    } finally {
      setState(() => _consultandoCep = false);
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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      Map<String, dynamic> result;

      if (widget.estabelecimento != null) {
        // EDIÇÃO
        print('Editando estabelecimento ID: ${widget.estabelecimento!['id']}');
        result = await _service.atualizarEstabelecimento(
          estabelecimentoId: widget.estabelecimento!['id'],
          token: token,
          nome: _nomeController.text.trim(),
          telefone: _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          rua: _ruaController.text.trim(),
          numero: _numeroController.text.trim(),
          complemento: _complementoController.text.trim().isEmpty
              ? null
              : _complementoController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim().toUpperCase(),
          cep: _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        );
      } else {
        // CRIAÇÃO
        result = await _service.criarEstabelecimento(
          token: token,
          nome: _nomeController.text.trim(),
          telefone: _telefoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          rua: _ruaController.text.trim(),
          numero: _numeroController.text.trim(),
          complemento: _complementoController.text.trim().isEmpty
              ? null
              : _complementoController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _estadoController.text.trim().toUpperCase(),
          cep: _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        );
      }

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar(
            widget.estabelecimento == null
                ? 'Estabelecimento criado com sucesso!'
                : 'Estabelecimento atualizado com sucesso!',
            Colors.green,
          );
          Navigator.pop(context, true);
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      print('Erro ao salvar: $e');
      _mostrarSnackBar('Erro: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.estabelecimento != null;

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
          isEditing ? 'Editar Estabelecimento' : 'Novo Estabelecimento',
          style: const TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nome
                    _buildTextField(
                      controller: _nomeController,
                      label: 'Nome do estabelecimento',
                      icon: Icons.store,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Telefone
                    _buildTextField(
                      controller: _telefoneController,
                      label: 'Telefone',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_telefoneMask],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Telefone é obrigatório';
                        }
                        String numeros = value.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        );
                        if (numeros.length != 11) {
                          return 'Telefone inválido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Seção Endereço
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF4A5C6B)),
                        const SizedBox(width: 8),
                        const Text(
                          'Endereço',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CEP
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
                              if (_cepConsultado) {
                                setState(() {
                                  _cepConsultado = false;
                                  _ultimoCepConsultado = null;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'CEP é obrigatório';
                              }
                              String numeros = value.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              if (numeros.length != 8) {
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
                                  child: const Icon(Icons.search),
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Cidade e Estado
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _cidadeController,
                            label: 'Cidade',
                            icon: Icons.location_city,
                            readOnly: _cepConsultado,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
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
                            readOnly: _cepConsultado,
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'UF é obrigatório';
                              }
                              if (value.length != 2) {
                                return 'Use 2 letras';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bairro
                    _buildTextField(
                      controller: _bairroController,
                      label: 'Bairro',
                      icon: Icons.map,
                      readOnly: _cepConsultado,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bairro é obrigatório';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Rua
                    _buildTextField(
                      controller: _ruaController,
                      label: 'Rua',
                      icon: Icons.streetview,
                      readOnly: _cepConsultado,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Rua é obrigatória';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Número e Complemento
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildTextField(
                            controller: _numeroController,
                            label: 'Número',
                            icon: Icons.numbers,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Número é obrigatório';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _complementoController,
                            label: 'Complemento',
                            icon: Icons.add_home,
                            validator: null,
                          ),
                        ),
                      ],
                    ),

                    if (_cepConsultado) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () =>
                            _limparCamposEndereco(excetoCep: false),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Buscar outro CEP'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4A5C6B),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF4A5C6B)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Color(0xFF4A5C6B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _salvar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A5C6B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Salvar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      readOnly: readOnly,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: readOnly ? Colors.grey : const Color(0xFF4A5C6B),
        ),
        prefixIcon: Icon(
          icon,
          color: readOnly ? Colors.grey : const Color(0xFF4A5C6B),
        ),
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
        filled: true,
        fillColor: readOnly ? const Color(0xFFEEEEEE) : const Color(0xFFF5F7FA),
        counterText: '',
      ),
    );
  }
}
