import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modSchedulingEnterprise.dart';
import '../../services/serSchedulingEmpresa.dart';
import '../../providers/proUser.dart';

class DetalheAgendamentoEmpresaScreen extends StatefulWidget {
  final int agendamentoId;

  const DetalheAgendamentoEmpresaScreen({
    super.key,
    required this.agendamentoId,
  });

  @override
  State<DetalheAgendamentoEmpresaScreen> createState() =>
      _DetalheAgendamentoEmpresaScreenState();
}

class _DetalheAgendamentoEmpresaScreenState
    extends State<DetalheAgendamentoEmpresaScreen> {
  final AgendamentoEmpresaService _agendamentoService =
      AgendamentoEmpresaService();
  AgendamentoEmpresa? _agendamento;
  bool _isLoading = true;
  String? _errorMessage;

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

      final result = await _agendamentoService.buscarAgendamento(
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
      setState(() {
        _errorMessage = 'Erro ao carregar agendamento: $e';
        _isLoading = false;
      });
    }
  }

  String _getStatusText(String status) {
    if (status == 'EM_ANDAMENTO') return 'EM ATENDIMENTO';
    return status;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDENTE':
        return Colors.orange;
      case 'CONFIRMADO':
        return Colors.green;
      case 'EM_ANDAMENTO':
        return Colors.blue;
      case 'CONCLUIDO':
        return Colors.purple;
      case 'CANCELADO':
        return Colors.red;
      case 'RECUSADO':
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarAgendamento,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5C6B),
                          foregroundColor: Colors.white
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _agendamento == null
                  ? const Center(child: Text('Agendamento não encontrado'))
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
                                        color: _getStatusColor(_agendamento!.status).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Text(
                                        _getStatusText(_agendamento!.status),
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
                                        _agendamento!.clienteNome,
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
                                if (_agendamento!.estabelecimentoNome != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Estabelecimento:',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          _agendamento!.estabelecimentoNome!,
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
                                value: _agendamento!.dataFormatada,
                              ),
                              _buildInfoRow(
                                icon: Icons.access_time,
                                label: 'Horário',
                                value: _agendamento!.horaServico,
                              ),
                              _buildInfoRow(
                                icon: Icons.person,
                                label: 'Prestador',
                                value: _agendamento!.prestadorNome,
                              ),
                              if (_agendamento!.clienteTelefone.isNotEmpty)
                                _buildInfoRow(
                                  icon: Icons.phone,
                                  label: 'Telefone do Cliente',
                                  value: _agendamento!.clienteTelefone,
                                ),
                              if (_agendamento!.observacao != null &&
                                  _agendamento!.observacao!.isNotEmpty)
                                _buildInfoRow(
                                  icon: Icons.note,
                                  label: 'Observação do Cliente',
                                  value: _agendamento!.observacao!,
                                  isMultiline: true,
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Serviços
                          _buildInfoSection(
                            title: 'Serviços (${_agendamento!.servicos.length})',
                            children: [
                              ..._agendamento!.servicos.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final servicoPreco = item['ServicoValor'] ?? 0.0;
                                final servico = item['servico'] ?? item;
                                final isLast = index == _agendamento!.servicos.length - 1;

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
                                                'R\$ ${servicoPreco.toStringAsFixed(2)}',
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
                                      'R\$ ${_agendamento!.valorTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4A5C6B),
                                      ),
                                    ),
                                    Text(
                                      '${_agendamento!.tempoGasto} minutos',
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

                          // Mostrar descrição/motivo se houver
                          if (_agendamento!.descricaoTrabalho != null &&
                              _agendamento!.descricaoTrabalho!.isNotEmpty) ...[
                            _buildInfoSection(
                              title: _agendamento!.status == 'CONCLUIDO'
                                  ? 'Descrição do Trabalho Realizado'
                                  : _agendamento!.status == 'RECUSADO' ? 'Motivo da Recusa' : 'Motivo do Cancelamento',
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    _agendamento!.descricaoTrabalho!,
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

                          // Observação (apenas leitura)
                          /*
                          const Text(
                            'Observações:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              _agendamento!.observacao?.isEmpty ?? true
                                  ? 'Nenhuma observação registrada'
                                  : _agendamento!.observacao!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A5C6B),
                              ),
                            ),
                          ),
                          */
                        ],
                      ),
                    ),
    );
  }

  /*
  String _getPrecoServico(Map<String, dynamic> servico) {
    return servico['ServicoValor']?.toStringAsFixed(2) ?? '0.00';
  }
  */

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