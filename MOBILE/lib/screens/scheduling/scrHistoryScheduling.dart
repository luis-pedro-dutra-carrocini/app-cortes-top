import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/serScheduling.dart';
import '../../providers/proUser.dart';

class HistoricoAgendamentosScreen extends StatefulWidget {
  const HistoricoAgendamentosScreen({super.key});

  @override
  State<HistoricoAgendamentosScreen> createState() =>
      _HistoricoAgendamentosScreenState();
}

class _HistoricoAgendamentosScreenState
    extends State<HistoricoAgendamentosScreen> {
  final AgendamentoService _agendamentoService = AgendamentoService();
  List<dynamic> _agendamentos = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Filtros
  DateTime? _dataInicio;
  DateTime? _dataFim;
  String? _statusFiltro;

  // Opções de status
  final List<Map<String, dynamic>> _statusOpcoes = [
    {'label': 'Todos', 'value': null},
    {'label': 'Pendente', 'value': 'PENDENTE'},
    {'label': 'Confirmado', 'value': 'CONFIRMADO'},
    {'label': 'Em Andamento', 'value': 'EM_ANDAMENTO'},
    {'label': 'Concluído', 'value': 'CONCLUIDO'},
    {'label': 'Cancelado', 'value': 'CANCELADO'},
    {'label': 'Recusado', 'value': 'RECUSADO'},
  ];

  // Controle de expansão
  final Set<int> _expandedItems = {};

  // Períodos pré-definidos
  final Map<String, Map<String, dynamic>> _periodosPreDefinidos = {
    'Último Mês': {
      'inicio': DateTime.now().subtract(const Duration(days: 30)),
      'fim': DateTime.now(),
    },
    'Últimos 3 Meses': {
      'inicio': DateTime.now().subtract(const Duration(days: 90)),
      'fim': DateTime.now(),
    },
    'Último Ano': {
      'inicio': DateTime.now().subtract(const Duration(days: 365)),
      'fim': DateTime.now(),
    },
  };

  @override
  void initState() {
    super.initState();
    _carregarAgendamentos();
  }

  Future<void> _carregarAgendamentos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _agendamentoService
          .listarMeusAgendamentosClienteTodos(
            token: token,
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            status: _statusFiltro,
          );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _agendamentos = result['data'] ?? [];
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
        _errorMessage = 'Erro ao carregar agendamentos: $e';
        _isLoading = false;
      });
    }
  }

  //(removido-limpeza)
  /*
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
  */

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDENTE':
        return Colors.orange;
      case 'CONFIRMADO':
        return Colors.blue;
      case 'EM_ANDAMENTO':
        return Colors.purple;
      case 'CONCLUIDO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      case 'RECUSADO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'PENDENTE':
        return 'Pendente';
      case 'CONFIRMADO':
        return 'Confirmado';
      case 'EM_ANDAMENTO':
        return 'Em Andamento';
      case 'CONCLUIDO':
        return 'Concluído';
      case 'CANCELADO':
        return 'Cancelado';
      case 'RECUSADO':
        return 'Recusado';
      default:
        return status ?? 'Desconhecido';
    }
  }

  String _getTituloDescricao(String status) {
    switch (status) {
      case 'CANCELADO':
        return 'Motivo do Cancelamento';
      case 'RECUSADO':
        return 'Motivo da Recusa';
      default:
        return 'Descrição do Trabalho';
    }
  }

  String _formatarMoeda(dynamic valor) {
    double valorDouble;
    if (valor is int) {
      valorDouble = valor.toDouble();
    } else if (valor is double) {
      valorDouble = valor;
    } else {
      valorDouble = 0.0;
    }
    return 'R\$ ${valorDouble.toStringAsFixed(2)}';
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  void _selecionarPeriodo() async {
    final periodoSelecionado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Período'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Períodos pré-definidos
            ..._periodosPreDefinidos.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                onTap: () {
                  Navigator.pop(context, entry.value);
                },
              );
            }),
            const Divider(),
            // Período personalizado
            ListTile(
              title: const Text('Personalizado'),
              onTap: () {
                Navigator.pop(context, {'personalizado': true});
              },
            ),
          ],
        ),
      ),
    );

    if (periodoSelecionado != null) {
      if (periodoSelecionado.containsKey('personalizado')) {
        // Calcular a data máxima (hoje + 3 meses)
        final hoje = DateTime.now();
        final dataMaxima = DateTime(hoje.year, hoje.month + 3, hoje.day);

        final dateRange = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: dataMaxima,
          initialDateRange: DateTimeRange(
            start:
                _dataInicio ??
                DateTime.now().subtract(const Duration(days: 30)),
            end: _dataFim ?? dataMaxima,
          ),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF4A5C6B),
                ),
              ),
              child: child!,
            );
          },
        );

        if (dateRange != null) {
          setState(() {
            _dataInicio = dateRange.start;
            _dataFim = dateRange.end;
          });
          _carregarAgendamentos();
        }
      } else {
        setState(() {
          _dataInicio = periodoSelecionado['inicio'];
          _dataFim = periodoSelecionado['fim'];
        });
        _carregarAgendamentos();
      }
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
          'Histórico de Agendamentos',
          style: TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // Botão de filtro
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF4A5C6B)),
            onPressed: _mostrarFiltros,
          ),
          // Botão de período
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF4A5C6B)),
            onPressed: _selecionarPeriodo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _carregarAgendamentos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A5C6B),
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : _agendamentos.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _agendamentos.length,
              itemBuilder: (context, index) {
                final agendamento = _agendamentos[index];
                return _buildAgendamentoCard(agendamento, index);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhum agendamento encontrado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seus agendamentos aparecerão aqui',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendamentoCard(dynamic agendamento, int index) {
    final isExpanded = _expandedItems.contains(index);
    final dataServico = DateTime.parse(agendamento['AgendamentoDtServico']);
    final status = agendamento['AgendamentoStatus'];
    final estabelecimento = agendamento['estabelecimento'];
    final prestador = agendamento['prestador'];
    final servicos = agendamento['servicos'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Cabeçalho do card (sempre visível)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedItems.remove(index);
                } else {
                  _expandedItems.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A5C6B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event,
                      color: Color(0xFF4A5C6B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estabelecimento != null &&
                                  estabelecimento['EstabelecimentoNome'] != null
                              ? estabelecimento['EstabelecimentoNome']
                              : prestador?['UsuarioNome'] ?? 'Prestador',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatarData(dataServico),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              agendamento['AgendamentoHoraServico'] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF4A5C6B),
                  ),
                ],
              ),
            ),
          ),

          // Conteúdo expandido
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações do prestador/estabelecimento
                  if (estabelecimento != null) ...[
                    _buildInfoRow(
                      label: 'Estabelecimento',
                      value:
                          estabelecimento['EstabelecimentoNome'] ??
                          'Não informado',
                    ),
                    if (estabelecimento['empresa'] != null)
                      _buildInfoRow(
                        label: 'Empresa',
                        value:
                            estabelecimento['empresa']['EmpresaNome'] ??
                            'Não informado',
                      ),
                    const SizedBox(height: 8),
                  ],

                  _buildInfoRow(
                    label: 'Prestador',
                    value: prestador?['UsuarioNome'] ?? 'Não informado',
                  ),
                  _buildInfoRow(
                    label: 'Telefone',
                    value: prestador?['UsuarioTelefone'] ?? 'Não informado',
                  ),

                  const Divider(height: 24),

                  // Serviços
                  const Text(
                    'Serviços Realizados',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...servicos.map(
                    (servico) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.build, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${servico['servico']['ServicoNome'] ?? 'Serviço'} - R\$ ${(servico['ServicoValor'] ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 24),

                  // Valores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tempo Total:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${agendamento['AgendamentoTempoGasto'] ?? 0} minutos',
                        style: const TextStyle(color: Color(0xFF4A5C6B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Valor Total:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatarMoeda(
                          agendamento['AgendamentoValorTotal'] ?? 0,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                  // Observação (se houver)
                  if (agendamento['AgendamentoObservacao'] != null &&
                      agendamento['AgendamentoObservacao'].isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'Observação',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      agendamento['AgendamentoObservacao'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],

                  // Descrição do trabalho / motivo (se houver)
                  if (agendamento['AgendamentoDescricaoTrabalho'] != null &&
                      agendamento['AgendamentoDescricaoTrabalho'].isNotEmpty &&
                      agendamento['AgendamentoStatus'] != 'CONCLUIDO') ...[
                    const Divider(height: 24),
                    Text(
                      _getTituloDescricao(agendamento['AgendamentoStatus']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      agendamento['AgendamentoDescricaoTrabalho'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A5C6B)),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? statusTemp = _statusFiltro;

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar por Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statusOpcoes.map((opcao) {
                      final isSelected = statusTemp == opcao['value'];
                      return FilterChip(
                        label: Text(opcao['label']),
                        selected: isSelected,
                        onSelected: (selected) {
                          setStateSheet(() {
                            statusTemp = selected ? opcao['value'] : null;
                          });
                        },
                        selectedColor: const Color(0xFF4A5C6B).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF4A5C6B),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF4A5C6B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _statusFiltro = statusTemp;
                            });
                            Navigator.pop(context);
                            _carregarAgendamentos();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A5C6B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
