import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/serEstablishment.dart';
import '../../providers/proUser.dart';

class ServicoEstabelecimentoFormScreen extends StatefulWidget {
  final int estabelecimentoId;
  final Map<String, dynamic>? servico;

  const ServicoEstabelecimentoFormScreen({
    super.key,
    required this.estabelecimentoId,
    this.servico,
  });

  @override
  State<ServicoEstabelecimentoFormScreen> createState() =>
      _ServicoEstabelecimentoFormScreenState();
}

class _ServicoEstabelecimentoFormScreenState
    extends State<ServicoEstabelecimentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _tempoController = TextEditingController();

  bool _isLoading = false;
  final EstabelecimentoService _service = EstabelecimentoService();

  @override
  void initState() {
    super.initState();
    if (widget.servico != null) {
      _nomeController.text = widget.servico!['ServicoNome'] ?? '';
      _descricaoController.text = widget.servico!['ServicoDescricao'] ?? '';
      _tempoController.text = widget.servico!['ServicoTempoMedio']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _tempoController.dispose();
    super.dispose();
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

      final tempo = int.parse(_tempoController.text);

      final result = widget.servico == null
          ? await _service.cadastrarServicoEstabelecimento(
              estabelecimentoId: widget.estabelecimentoId,
              nome: _nomeController.text,
              descricao: _descricaoController.text,
              tempoMedio: tempo,
              token: token,
            )
          : await _service.atualizarServicoEstabelecimento(
              servicoId: widget.servico!['ServicoEstabelecimentoId'],
              nome: _nomeController.text,
              descricao: _descricaoController.text,
              tempoMedio: tempo,
              ativo: widget.servico!['ServicoAtivo'] ?? true,
              token: token,
            );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar(
            widget.servico == null
                ? 'Serviço cadastrado com sucesso'
                : 'Serviço atualizado com sucesso',
            Colors.green,
          );
          Navigator.pop(context, true);
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.servico != null;

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
          isEditing ? 'Editar Serviço' : 'Novo Serviço',
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
                  children: [
                    _buildTextField(
                      controller: _nomeController,
                      label: 'Nome do serviço',
                      icon: Icons.build,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nome é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descricaoController,
                      label: 'Descrição (opcional)',
                      icon: Icons.description,
                      maxLines: 3,
                      validator: null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _tempoController,
                      label: 'Tempo médio (minutos)',
                      icon: Icons.access_time,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Tempo médio é obrigatório';
                        }
                        final tempo = int.tryParse(value);
                        if (tempo == null || tempo <= 0) {
                          return 'Informe um número válido maior que zero';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
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
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4A5C6B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4A5C6B), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
      ),
    );
  }
}