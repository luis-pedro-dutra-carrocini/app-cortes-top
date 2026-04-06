import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modAvailability.dart';
import '../../services/serAvailability.dart';
import '../../providers/proUser.dart';

class EditarDisponibilidadeScreen extends StatefulWidget {
  final Disponibilidade disponibilidade;

  const EditarDisponibilidadeScreen({super.key, required this.disponibilidade});

  @override
  State<EditarDisponibilidadeScreen> createState() =>
      _EditarDisponibilidadeScreenState();
}

class _EditarDisponibilidadeScreenState
    extends State<EditarDisponibilidadeScreen> {
  late Disponibilidade _disponibilidade;
  final _formKey = GlobalKey<FormState>();

  DateTime? _dataSelecionada;
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFimController = TextEditingController();

  bool _isLoading = false;
  final DisponibilidadeService _disponibilidadeService =
      DisponibilidadeService();

  List<dynamic> _estabelecimentosVinculados = [];
  // ignore: unnecessary_question_mark
  dynamic? _estabelecimentoSelecionado;
  bool _carregandoEstabelecimentos = false;
  bool _usandoEstabelecimento = false;
  int? _estabelecimentoIdOriginal;

  @override
  void initState() {
    super.initState();
    _disponibilidade = widget.disponibilidade;
    print('Disponibilidade recebida: ${_disponibilidade.toJson()}'); // LOG
    print('EstabelecimentoId: ${_disponibilidade.estabelecimentoId}'); // LOG
    _preencherCampos();
    _carregarEstabelecimentosVinculados();
  }

  void _preencherCampos() {
    _dataSelecionada = _disponibilidade.data;
    _horaInicioController.text = _disponibilidade.horaInicio;
    _horaFimController.text = _disponibilidade.horaFim;

    // Verificar se a disponibilidade pertence a um estabelecimento
    if (_disponibilidade.estabelecimentoId != null) {
      _usandoEstabelecimento = true;
      _estabelecimentoIdOriginal = _disponibilidade.estabelecimentoId;
    }
  }

  @override
  void dispose() {
    _horaInicioController.dispose();
    _horaFimController.dispose();
    super.dispose();
  }

  // NOVO: método para selecionar data
  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada!,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A5C6B)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  Future<void> _selecionarHora(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A5C6B)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hora = picked.hour.toString().padLeft(2, '0');
      final minuto = picked.minute.toString().padLeft(2, '0');
      controller.text = '$hora:$minuto';
    }
  }

  Future<void> _carregarEstabelecimentosVinculados() async {
    setState(() => _carregandoEstabelecimentos = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) {
        setState(() => _carregandoEstabelecimentos = false);
        return;
      }

      final result = await _disponibilidadeService
          .buscarEstabelecimentosVinculados(token);

      if (mounted) {
        if (result['success']) {
          setState(() {
            _estabelecimentosVinculados = result['data'] ?? [];
            _carregandoEstabelecimentos = false;

            // Se a disponibilidade era de um estabelecimento, pré-selecionar
            if (_estabelecimentoIdOriginal != null) {
              _estabelecimentoSelecionado = _estabelecimentosVinculados
                  .firstWhere(
                    (est) =>
                        est['estabelecimento']?['EstabelecimentoId'] ==
                        _estabelecimentoIdOriginal,
                    orElse: () => null,
                  );
            }
          });
        } else {
          setState(() => _carregandoEstabelecimentos = false);
        }
      }
    } catch (e) {
      setState(() => _carregandoEstabelecimentos = false);
    }
  }

  // NOVO: método para formatar data
  String _formatarData(DateTime data) {
    const dias = [
      'Domingo',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
    ];
    return '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year} - ${dias[data.weekday % 7]}';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar se selecionou estabelecimento quando necessário
    if (_usandoEstabelecimento && _estabelecimentoSelecionado == null) {
      _mostrarSnackBar('Selecione um estabelecimento', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) {
        _mostrarSnackBar('Usuário não autenticado', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // MODIFICADO: chamar serviço com data em vez de diaSemana
      final result = await _disponibilidadeService.atualizarDisponibilidade(
        disponibilidadeId: _disponibilidade.id,
        token: token,
        data: _dataSelecionada!,
        horaInicio: _horaInicioController.text,
        horaFim: _horaFimController.text,
        estabelecimentoId:
            _usandoEstabelecimento && _estabelecimentoSelecionado != null
            ? _estabelecimentoSelecionado?['estabelecimento']?['EstabelecimentoId']
            : null,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar('Horário atualizado com sucesso!', Colors.green);
          Navigator.pop(context, true);
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
          'Editar Disponibilidade',
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
                // Ícone ilustrativo
                Center(
                  child: Container(
                    height: 100,
                    width: 100,
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A5C6B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_calendar,
                      size: 50,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                ),

                // Opção de escolha entre disponibilidade pessoal ou de estabelecimento
                if (_estabelecimentosVinculados.isNotEmpty ||
                    _estabelecimentoIdOriginal != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo de disponibilidade:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Pessoal'),
                                selected: !_usandoEstabelecimento,
                                onSelected: (selected) {
                                  setState(() {
                                    _usandoEstabelecimento = !selected;
                                    if (!_usandoEstabelecimento) {
                                      _estabelecimentoSelecionado = null;
                                    }
                                  });
                                },
                                selectedColor: const Color(
                                  0xFF4A5C6B,
                                ).withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: !_usandoEstabelecimento
                                      ? const Color(0xFF4A5C6B)
                                      : Colors.grey,
                                  fontWeight: !_usandoEstabelecimento
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Em estabelecimento'),
                                selected: _usandoEstabelecimento,
                                onSelected: (selected) {
                                  setState(() {
                                    _usandoEstabelecimento = selected;
                                  });
                                },
                                selectedColor: const Color(
                                  0xFF4A5C6B,
                                ).withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: _usandoEstabelecimento
                                      ? const Color(0xFF4A5C6B)
                                      : Colors.grey,
                                  fontWeight: _usandoEstabelecimento
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Seletor de estabelecimento (se a opção for por estabelecimento)
                  if (_usandoEstabelecimento) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _carregandoEstabelecimentos
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4A5C6B),
                                ),
                              ),
                            )
                          : DropdownButtonFormField<dynamic>(
                              value: _estabelecimentoSelecionado,
                              hint: const Text('Selecione um estabelecimento'),
                              isExpanded: true,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              items: _estabelecimentosVinculados
                                  .where(
                                    (est) =>
                                        est['UsuarioEstabelecimentoStatus'] ==
                                        'ATIVO',
                                  ) // <-- FILTRAR APENAS ATIVOS
                                  .map((est) {
                                    return DropdownMenuItem(
                                      value: est,
                                      child: Text(
                                        est['estabelecimento']?['EstabelecimentoNome'] ??
                                            '',
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _estabelecimentoSelecionado = value;
                                });
                              },
                              validator: (value) {
                                if (_usandoEstabelecimento && value == null) {
                                  return 'Selecione um estabelecimento';
                                }
                                return null;
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // Seletor de data
                InkWell(
                  onTap: _selecionarData,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF4A5C6B),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _formatarData(_dataSelecionada!),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4A5C6B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF4A5C6B),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Hora início
                TextFormField(
                  controller: _horaInicioController,
                  readOnly: true,
                  onTap: () => _selecionarHora(_horaInicioController),
                  decoration: InputDecoration(
                    labelText: 'Hora de início',
                    labelStyle: const TextStyle(color: Color(0xFF4A5C6B)),
                    prefixIcon: const Icon(
                      Icons.access_time,
                      color: Color(0xFF4A5C6B),
                    ),
                    suffixIcon: const Icon(
                      Icons.arrow_drop_down,
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
                      return 'Hora de início é obrigatória';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Hora fim
                TextFormField(
                  controller: _horaFimController,
                  readOnly: true,
                  onTap: () => _selecionarHora(_horaFimController),
                  decoration: InputDecoration(
                    labelText: 'Hora de fim',
                    labelStyle: const TextStyle(color: Color(0xFF4A5C6B)),
                    prefixIcon: const Icon(
                      Icons.access_time,
                      color: Color(0xFF4A5C6B),
                    ),
                    suffixIcon: const Icon(
                      Icons.arrow_drop_down,
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
                      return 'Hora de fim é obrigatória';
                    }

                    if (_horaInicioController.text.isNotEmpty) {
                      if (value.compareTo(_horaInicioController.text) <= 0) {
                        return 'Hora de fim deve ser maior que hora de início';
                      }
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
}
