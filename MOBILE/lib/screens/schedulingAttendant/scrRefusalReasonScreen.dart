import 'package:flutter/material.dart';

class RecusaMotivoScreen extends StatefulWidget {
  final bool isRecusa;
  final Function(String) onConfirm;

  const RecusaMotivoScreen({
    super.key,
    required this.isRecusa,
    required this.onConfirm,
  });

  @override
  State<RecusaMotivoScreen> createState() => _RecusaMotivoScreenState();
}

class _RecusaMotivoScreenState extends State<RecusaMotivoScreen> {
  final TextEditingController _motivoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isRecusa ? Icons.cancel : Icons.warning_amber_rounded,
                      color: widget.isRecusa ? Colors.red : Colors.orange,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isRecusa ? 'Recusar Agendamento' : 'Cancelar Agendamento',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.isRecusa
                          ? 'Por favor, informe o motivo da recusa:'
                          : 'Por favor, informe o motivo do cancelamento:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _motivoController,
                      maxLines: 5,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: widget.isRecusa
                            ? 'Ex: Não tenho disponibilidade no horário...'
                            : 'Descreva o motivo do cancelamento...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                        if (value == null || value.trim().isEmpty) {
                          return widget.isRecusa
                              ? 'Informe o motivo da recusa'
                              : 'Informe o motivo do cancelamento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Esta ação não poderá ser desfeita.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Voltar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4A5C6B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                widget.onConfirm(_motivoController.text.trim());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.isRecusa ? Colors.red : Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              widget.isRecusa ? 'Recusar' : 'Cancelar',
                              style: const TextStyle(fontSize: 16),
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
        ),
      ),
    );
  }
}