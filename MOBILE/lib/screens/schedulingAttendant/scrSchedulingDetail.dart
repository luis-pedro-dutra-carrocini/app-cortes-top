import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modSchedulingAttendant.dart';
import '../../services/serSchedulingAttendant.dart';
import '../../providers/proUser.dart';
import 'scrRefusalReasonScreen.dart';

class DetalheAgendamentoPrestadorScreen extends StatefulWidget {
  final AgendamentoPrestador agendamento;

  const DetalheAgendamentoPrestadorScreen({
    super.key,
    required this.agendamento,
  });

  @override
  State<DetalheAgendamentoPrestadorScreen> createState() =>
      _DetalheAgendamentoPrestadorScreenState();
}

class _DetalheAgendamentoPrestadorScreenState
    extends State<DetalheAgendamentoPrestadorScreen> {
  late AgendamentoPrestador _agendamento;
  bool _isLoading = false;
  final TextEditingController _descricaoController = TextEditingController();

  final AgendamentoPrestadorService _agendamentoService =
      AgendamentoPrestadorService();

  @override
  void initState() {
    super.initState();
    _agendamento = widget.agendamento;
    _agendamento.statusDescricao = _agendamento.status;
    if (_agendamento.statusDescricao == 'EM_ANDAMENTO') {
      _agendamento.statusDescricao = 'EM ATENDIMENTO';
    }
    _descricaoController.text = _agendamento.descricaoTrabalho ?? '';
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _voltarParaPendente() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.undo, color: Colors.orange, size: 50),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voltar para Pendente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text(
              'Deseja realmente voltar este agendamento para pendente?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sim, voltar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _agendamentoService.atualizarStatus(
        agendamentoId: _agendamento.id,
        token: token,
        status: 'PENDENTE',
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _agendamento = _agendamento.copyWith(status: 'PENDENTE');
            _isLoading = false;
          });
          _mostrarSnackBar('Agendamento voltou para pendente!', Colors.orange);
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

  Future<void> _confirmarAgendamento() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Confirmar Agendamento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text('Confirma este agendamento?', textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _agendamentoService.confirmarAgendamento(
        agendamentoId: _agendamento.id,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _agendamento = _agendamento.copyWith(status: 'CONFIRMADO');
            _isLoading = false;
          });
          _mostrarSnackBar('Agendamento confirmado!', Colors.green);
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

  Future<void> _iniciarAgendamento() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.play_circle, color: Colors.blue, size: 50),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Iniciar Agendamento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text(
              'Confirma o início deste agendamento?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _agendamentoService.atualizarStatus(
        agendamentoId: _agendamento.id,
        token: token,
        status: 'EM_ANDAMENTO',
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _agendamento = _agendamento.copyWith(status: 'EM_ANDAMENTO');
            _isLoading = false;
          });
          _mostrarSnackBar('Agendamento iniciado!', Colors.green);
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

  Future<void> _cancelarAgendamento() async {
    // Verificar se pode cancelar
    if (!_agendamento.podeRecusar) {
      _mostrarSnackBar(
        'Não é possível cancelar um agendamento ${_agendamento.status.toLowerCase()}',
        Colors.red,
      );
      return;
    }

    final isRecusa = _agendamento.status == 'PENDENTE';

    // Abrir tela de motivo
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecusaMotivoScreen(
        isRecusa: isRecusa,
        onConfirm: (motivo) async {
          Navigator.pop(context); // Fechar bottom sheet

          setState(() => _isLoading = true);

          try {
            final usuarioProvider = Provider.of<UsuarioProvider>(
              context,
              listen: false,
            );
            final token = usuarioProvider.token;

            if (token == null) return;

            final apiResult = await _agendamentoService.cancelarAgendamento(
              agendamentoId: _agendamento.id,
              token: token,
              motivo: motivo,
            );

            if (mounted) {
              if (apiResult['success']) {
                // CORREÇÃO: Atualizar o agendamento local com o novo status e motivo
                setState(() {
                  _agendamento = _agendamento.copyWith(
                    status: isRecusa ? 'RECUSADO' : 'CANCELADO',
                    descricaoTrabalho: motivo,
                  );
                  _isLoading = false;
                });

                // Mostrar mensagem de sucesso
                _mostrarSnackBar(
                  isRecusa
                      ? 'Agendamento recusado com sucesso'
                      : 'Agendamento cancelado com sucesso',
                  Colors.green,
                );

                // NÃO usar Navigator.pop aqui - apenas atualiza o estado
              } else {
                setState(() => _isLoading = false);
                _mostrarSnackBar(apiResult['message'], Colors.red);
              }
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              _mostrarSnackBar('Erro: $e', Colors.red);
            }
          }
        },
      ),
    );
  }

  Future<void> _finalizarAgendamento() async {
    if (_descricaoController.text.trim().isEmpty) {
      _mostrarSnackBar('Descreva o trabalho realizado', Colors.orange);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Finalizar Agendamento',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text(
              'Confirma a conclusão deste agendamento?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _agendamentoService.atualizarStatus(
        agendamentoId: _agendamento.id,
        token: token,
        status: 'CONCLUIDO',
        descricaoTrabalho: _descricaoController.text.trim(),
      );

      if (mounted) {
        if (result['success']) {
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
          'Detalhes do Agendamento',
          style: TextStyle(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de status
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4A5C6B),
                          const Color(0xFF6B7F8F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _agendamento.statusColor.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                _agendamento.statusDescricao,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cliente:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _agendamento.clienteNome,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Informações do agendamento
                  _buildInfoSection(
                    title: 'Informações do Agendamento',
                    children: [
                      _buildInfoRow(
                        icon: Icons.calendar_today,
                        label: 'Data',
                        value: _agendamento.dataFormatada,
                      ),
                      _buildInfoRow(
                        icon: Icons.access_time,
                        label: 'Horário',
                        value: _agendamento.horaServico,
                      ),
                      if (_agendamento.observacao != null &&
                          _agendamento.observacao!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.note,
                          label: 'Observação do Cliente',
                          value: _agendamento.observacao!,
                          isMultiline: true,
                        ),
                      _buildInfoRow(
                        icon: Icons.phone,
                        label: 'Telefone do Cliente',
                        value: _agendamento.clienteTelefone.isEmpty
                            ? 'Não informado'
                            : _agendamento.clienteTelefone,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Serviços
                  _buildInfoSection(
                    title: 'Serviços (${_agendamento.servicos.length})',
                    children: [
                      ..._agendamento.servicos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final servico = item['servico'] ?? item;
                        final isLast =
                            index == _agendamento.servicos.length - 1;

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4A5C6B,
                                      ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.build,
                                      size: 14,
                                      color: Color(0xFF4A5C6B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          servico['ServicoNome'] ?? 'Serviço',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF4A5C6B),
                                          ),
                                        ),
                                        if (servico['ServicoDescricao'] != null)
                                          Text(
                                            servico['ServicoDescricao'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'R\$ ${_getPrecoServico(servico)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4A5C6B),
                                        ),
                                      ),
                                      Text(
                                        '${servico['ServicoTempoMedio'] ?? 0} min',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast) const Divider(height: 1),
                          ],
                        );
                      }),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Totais
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'R\$ ${_agendamento.valorTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A5C6B),
                              ),
                            ),
                            Text(
                              '${_agendamento.tempoGasto} minutos',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Campo de descrição do trabalho (para finalização)
                  if (_agendamento.status == 'EM_ANDAMENTO') ...[
                    const Text(
                      'Descrição do Trabalho Realizado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descricaoController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Descreva o trabalho realizado...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF4A5C6B),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Botões de ação
                  // Botões de ação baseados no status
                  if (_agendamento.podeConfirmar) ...[
                    ElevatedButton.icon(
                      onPressed: _confirmarAgendamento,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirmar Agendamento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_agendamento.podeIniciar) ...[
                    ElevatedButton.icon(
                      onPressed: _iniciarAgendamento,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Atendimento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_agendamento.podeVoltarPendente) ...[
                    ElevatedButton.icon(
                      onPressed: _voltarParaPendente,
                      icon: const Icon(Icons.undo),
                      label: const Text('Voltar para Pendente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_agendamento.podeFinalizar) ...[
                    ElevatedButton.icon(
                      onPressed: _finalizarAgendamento,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Finalizar Atendimento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_agendamento.podeRecusar) ...[
                    OutlinedButton.icon(
                      onPressed: _cancelarAgendamento,
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text(
                        'Recusar Agendamento',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],

                  // Após o Container dos totais, adicione:
                  const SizedBox(height: 20),

                  // Mostrar descrição/motivo baseado no status
                  if (_agendamento.mostrarDescricao &&
                      _agendamento.descricaoTrabalho != null &&
                      _agendamento.descricaoTrabalho!.isNotEmpty) ...[
                    _buildInfoSection(
                      title: _agendamento.tituloDescricao,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _agendamento.descricaoTrabalho!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A5C6B),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }

  String _getPrecoServico(Map<String, dynamic> servico) {
    if (servico['precoAtual'] != null) {
      return servico['precoAtual'].toStringAsFixed(2);
    }
    if (servico['precos'] != null && servico['precos'].length > 0) {
      return servico['precos'][0]['ServicoValor'].toStringAsFixed(2);
    }
    return '0.00';
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4A5C6B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5C6B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
