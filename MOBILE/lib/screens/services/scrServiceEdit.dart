import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/modService.dart';
import '../../services/serService.dart';
import '../../providers/proUser.dart';

class EditarServicoScreen extends StatefulWidget {
  final Servico servico;

  const EditarServicoScreen({super.key, required this.servico});

  @override
  State<EditarServicoScreen> createState() => _EditarServicoScreenState();
}

class _EditarServicoScreenState extends State<EditarServicoScreen> {
  late Servico _servico;
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _tempoController = TextEditingController();

  bool _isLoading = false;
  final ServicoService _servicoService = ServicoService();

  @override
  void initState() {
    super.initState();
    _servico = widget.servico;
    _preencherCampos();
  }

  String? _getToken() {
    final usuarioProvider = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    );
    return usuarioProvider.token;
  }

  void _preencherCampos() {
    _nomeController.text = _servico.nome;
    _descricaoController.text = _servico.descricao ?? '';
    _tempoController.text = _servico.tempoMedio.toString();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = _getToken();
      if (token == null) {
        _mostrarSnackBar('Usuário não autenticado', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final result = await _servicoService.atualizarServico(
        servicoId: _servico.id,
        token: token,
        nome: _nomeController.text.trim(),
        descricao: _descricaoController.text.isNotEmpty
            ? _descricaoController.text.trim()
            : null,
        tempoMedio: int.parse(_tempoController.text),
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar('Serviço atualizado com sucesso!', Colors.green);
          Navigator.pop(context, true); // Retorna true indicando sucesso
        } else {
          setState(() => _isLoading = false);
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarSnackBar('Erro: $e', Colors.red);
      }
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A5C6B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Serviço',
          style: TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nome do serviço
                _buildTextField(
                  controller: _nomeController,
                  label: 'Nome do serviço',
                  icon: Icons.build_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Descrição
                _buildTextField(
                  controller: _descricaoController,
                  label: 'Descrição (opcional)',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                  validator: null,
                ),

                const SizedBox(height: 16),

                // Tempo médio
                _buildTextField(
                  controller: _tempoController,
                  label: 'Tempo médio (minutos)',
                  icon: Icons.access_time,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tempo médio é obrigatório';
                    }
                    final tempo = int.tryParse(value);
                    if (tempo == null || tempo <= 0) {
                      return 'Tempo deve ser maior que zero';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF4A5C6B)),
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
                        onPressed: _isLoading ? null : _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5C6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
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
