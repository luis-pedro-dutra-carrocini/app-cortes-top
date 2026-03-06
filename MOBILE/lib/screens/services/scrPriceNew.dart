import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/serService.dart';
import 'package:provider/provider.dart';
import '../../providers/proUser.dart';

class NovoPrecoScreen extends StatefulWidget {
  final int servicoId;
  final String servicoNome;

  const NovoPrecoScreen({
    super.key,
    required this.servicoId,
    required this.servicoNome,
  });

  @override
  State<NovoPrecoScreen> createState() => _NovoPrecoScreenState();
}

class _NovoPrecoScreenState extends State<NovoPrecoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  bool _isLoading = false;
  final ServicoService _servicoService = ServicoService();

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  String? _getToken() {
    final usuarioProvider = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    );
    return usuarioProvider.token;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Converter valor para double
      final valorTexto = _valorController.text.replaceAll(',', '.');
      final valor = double.parse(valorTexto);

      final token = _getToken();
      if (token == null) {
        _mostrarSnackBar('Usuário não autenticado', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final result = await _servicoService.adicionarPreco(
        servicoId: widget.servicoId,
        token: token,
        valor: valor,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarDialogSucesso();
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

  void _mostrarDialogSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Preço Adicionado!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Novo preço registrado com sucesso',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fechar dialog
              Navigator.pop(context, true); // Voltar
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
          'Novo Preço',
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
                // Informações do serviço
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A5C6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.build_circle,
                        size: 40,
                        color: Color(0xFF4A5C6B),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.servicoNome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A5C6B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Campo de valor
                TextFormField(
                  controller: _valorController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Valor (R\$)',
                    labelStyle: const TextStyle(color: Color(0xFF4A5C6B)),
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Color(0xFF4A5C6B),
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
                      borderSide: const BorderSide(
                        color: Color(0xFF4A5C6B),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Valor é obrigatório';
                    }
                    final valor = double.tryParse(value.replaceAll(',', '.'));
                    if (valor == null || valor <= 0) {
                      return 'Valor deve ser maior que zero';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Botão salvar
                ElevatedButton(
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
                          'Adicionar Preço',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
