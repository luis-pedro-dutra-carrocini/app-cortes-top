import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modScheduling.dart';
import '../../services/serScheduling.dart';
import '../../providers/proUser.dart';
import 'scrSchedulingEdit.dart';

class DetalhesAgendamentoScreen extends StatefulWidget {
  final int agendamentoId;

  const DetalhesAgendamentoScreen({super.key, required this.agendamentoId});

  @override
  State<DetalhesAgendamentoScreen> createState() => _SchedulingDetailScreenState();
}

class _SchedulingDetailScreenState extends State<DetalhesAgendamentoScreen> {
  Agendamento? _agendamento;
  bool _isLoading = true;
  String? _errorMessage;
  final AgendamentoService _agendamentoService = AgendamentoService();

  @override
  void initState() {
    super.initState();
    _carregarAgendamento();
  }

  Future<void> _carregarAgendamento() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _agendamentoService.buscarAgendamentoPorId(
        agendamentoId: widget.agendamentoId,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _agendamento = result['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erro ao carregar agendamento: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelarAgendamento() async {
    String? motivo;

    final motivoDialog = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 50,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cancelar Agendamento',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                'Informe o motivo do cancelamento:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              TextFormField(
                maxLines: 3,
                autofocus: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'Descreva o motivo do cancelamento...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF4A5C6B),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) => motivo = value,
                onFieldSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(context, value);
                  }
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Esta ação não poderá ser desfeita.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivo == null || motivo!.trim().isEmpty) {
                _mostrarSnackBar(
                  'Informe o motivo do cancelamento',
                  Colors.orange,
                );
                return;
              }
              Navigator.pop(context, motivo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar Agendamento'),
          ),
        ],
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      ),
    );

    if (motivoDialog == null) return;

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _agendamentoService.cancelarAgendamento(
        agendamentoId: widget.agendamentoId,
        token: token,
        motivo: motivoDialog,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar('Agendamento cancelado com sucesso!', Colors.green);
          Navigator.pop(context, true); // Voltar para tela anterior com sucesso
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

  Color _getStatusColorValue() {
    switch (_agendamento?.status) {
      case 'PENDENTE':
        return Colors.orange;
      case 'CONFIRMADO':
        return Colors.green;
      case 'EM_ANDAMENTO':
        return Colors.blue;
      case 'CONCLUIDO':
        return Colors.grey;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
          : _errorMessage != null
          ? _buildErrorWidget()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
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
                colors: [const Color(0xFF4A5C6B), const Color(0xFF6B7F8F)],
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
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColorValue().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        _agendamento?.status ?? 'PENDENTE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_agendamento?.estabelecimento?['EstabelecimentoNome'] !=
                    null) ...[
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Empresa:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Expanded(
                        child: Text(
                          _agendamento?.estabelecimento?['empresa']?['EmpresaNome'] ??
                              'Carregando...',
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
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estabelecimento:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Expanded(
                        child: Text(
                          _agendamento
                                  ?.estabelecimento?['EstabelecimentoNome'] ??
                              'Carregando...',
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
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Prestador:',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Expanded(
                      child: Text(
                        _agendamento?.prestador?['UsuarioNome'] ??
                            'Carregando...',
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
                value: _agendamento?.dataFormatada ?? '',
              ),
              _buildInfoRow(
                icon: Icons.access_time,
                label: 'Horário',
                value: _agendamento?.horaServico ?? '',
              ),
              _buildInfoRow(
                icon: Icons.location_city,
                label: 'Endereço',
                value: _agendamento?.endereco ?? '',
              ),
              if (_agendamento?.observacao != null &&
                  _agendamento!.observacao!.isNotEmpty)
                _buildInfoRow(
                  icon: Icons.note,
                  label: 'Observação',
                  value: _agendamento!.observacao!,
                  isMultiline: true,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Serviços selecionados
          _buildInfoSection(
            title: 'Serviços (${_agendamento?.servicos?.length ?? 0})',
            children: [
              ...?_agendamento?.servicos?.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final servico = item['servico'] ?? item;
                final isLast = index == (_agendamento!.servicos!.length - 1);

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
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A5C6B).withOpacity(0.1),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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

          const SizedBox(height: 20),

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
                      'R\$ ${_agendamento?.valorTotal.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    Text(
                      '${_agendamento?.tempoGasto ?? 0} minutos',
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

          const SizedBox(height: 24),

          // Botões de ação (se possível)
          if (_agendamento?.podeEditar ?? false) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                // Botão Cancelar
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelarAgendamento,
                    label: const Text(
                      'Deletar',
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
                ),
                const SizedBox(width: 12),
                // Botão Editar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditarAgendamentoScreen(agendamento: _agendamento!),
                        ),
                      ).then((atualizado) {
                        if (atualizado == true) {
                          _carregarAgendamento();
                        }
                      });
                    },
                    label: const Text(
                      'Editar',
                      style: TextStyle(color: Colors.white),
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
                ),
              ],
            ),
          ] else if (_agendamento?.podeCancelar ?? false) ...[
            // Apenas botão de cancelar (se não puder editar mas puder cancelar)
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _cancelarAgendamento,
              label: const Text(
                'Deletar Agendamento',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 48), // Largura total
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getPrecoServico(Map<String, dynamic> servico) {
    // PRIORIDADE 1: Valor armazenado no momento do agendamento (campo valorNoMomento)
    if (servico['valorNoMomento'] != null) {
      return servico['valorNoMomento'].toStringAsFixed(2);
    }

    // PRIORIDADE 2: Se por algum motivo não tiver valorNoMomento, tenta o precoAtual
    if (servico['precoAtual'] != null) {
      return servico['precoAtual'].toStringAsFixed(2);
    }

    // PRIORIDADE 3: Tenta buscar na lista de preços
    if (servico['precos'] != null && servico['precos'].length > 0) {
      return servico['precos'][0]['ServicoValor'].toStringAsFixed(2);
    }

    // VALOR PADRÃO
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

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erro ao carregar agendamento',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarAgendamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A5C6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
