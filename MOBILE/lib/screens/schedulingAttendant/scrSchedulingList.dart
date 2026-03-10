import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modSchedulingAttendant.dart';
import '../../services/serSchedulingAttendant.dart';
import '../../providers/proUser.dart';
import 'scrSchedulingDetail.dart';

class ListaAgendamentosPrestadorScreen extends StatefulWidget {
  const ListaAgendamentosPrestadorScreen({super.key});

  @override
  State<ListaAgendamentosPrestadorScreen> createState() =>
      _ListaAgendamentosPrestadorScreenState();
}

class _ListaAgendamentosPrestadorScreenState
    extends State<ListaAgendamentosPrestadorScreen> {
  final AgendamentoPrestadorService _agendamentoService =
      AgendamentoPrestadorService();
  List<AgendamentoPrestador> _agendamentos = [];
  List<AgendamentoPrestador> _agendamentosFiltrados = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filtros
  String _filtroStatus = 'TODOS';
  final List<String> _statusOptions = [
    'TODOS',
    'PENDENTE',
    'CONFIRMADO',
    'EM_ANDAMENTO',
    'CONCLUIDO',
    'CANCELADO',
    'RECUSADO',
  ];

  // Adicione estas variáveis após as existentes
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _mostrarFiltroData = false;

  @override
  void initState() {
    super.initState();
    _carregarAgendamentosComFiltro();
  }

  Future<void> _selecionarPeriodo() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dataInicio != null && _dataFim != null
          ? DateTimeRange(start: _dataInicio!, end: _dataFim!)
          : null,
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
        _dataInicio = picked.start;
        _dataFim = picked.end;
      });
      _carregarAgendamentosComFiltro();
    }
  }

  // Verifica se o filtro "Hoje" está ativo
  bool _isFiltroHojeAtivo() {
    if (_dataInicio == null || _dataFim == null) return false;

    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final fimHoje = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);

    return _dataInicio!.isAtSameMomentAs(inicioHoje) &&
        _dataFim!.isAtSameMomentAs(fimHoje);
  }

  // Verifica se o filtro "Este Mês" está ativo
  bool _isFiltroMesAtivo() {
    if (_dataInicio == null || _dataFim == null) return false;

    final hoje = DateTime.now();
    final inicioMes = DateTime(hoje.year, hoje.month, 1);
    final fimMes = DateTime(hoje.year, hoje.month + 1, 0, 23, 59, 59);

    return _dataInicio!.isAtSameMomentAs(inicioMes) &&
        _dataFim!.isAtSameMomentAs(fimMes);
  }

  // Verifica se o filtro "Últimos 30 dias" está ativo
  bool _isFiltro30DiasAtivo() {
    if (_dataInicio == null || _dataFim == null) return false;

    final hoje = DateTime.now();
    final fimHoje = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
    final inicio30Dias = hoje.subtract(const Duration(days: 30));
    final inicio30DiasNormalizado = DateTime(
      inicio30Dias.year,
      inicio30Dias.month,
      inicio30Dias.day,
    );

    return _dataInicio!.isAtSameMomentAs(inicio30DiasNormalizado) &&
        _dataFim!.isAtSameMomentAs(fimHoje);
  }

  Future<void> _limparFiltroData() async {
    setState(() {
      _dataInicio = null;
      _dataFim = null;
    });
    _carregarAgendamentosComFiltro();
  }

  Future<void> _carregarAgendamentosComFiltro() async {
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

      final result = await _agendamentoService.listarMeusAgendamentos(
        token: token,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _agendamentos = result['data'];
            _aplicarFiltro();
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
          _errorMessage = 'Erro ao carregar agendamentos: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _aplicarFiltro() {
    setState(() {
      if (_filtroStatus == 'TODOS') {
        _agendamentosFiltrados = List.from(_agendamentos);
      } else {
        _agendamentosFiltrados = _agendamentos
            .where((a) => a.status == _filtroStatus)
            .toList();
      }

      // Ordenar por data (mais recentes primeiro)
      _agendamentosFiltrados.sort(
        (a, b) => b.dataServico.compareTo(a.dataServico),
      );
    });
  }

  int _getCountPorStatus(String status) {
    if (status == 'TODOS') return _agendamentos.length;
    return _agendamentos.where((a) => a.status == status).length;
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
          'Meus Agendamentos',
          style: TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4A5C6B)),
            onPressed: _carregarAgendamentosComFiltro,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarAgendamentosComFiltro,
          color: const Color(0xFF4A5C6B),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
                )
              : _errorMessage != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    // Cards de resumo
                    _buildResumoCard(),

                    // Após _buildResumoCard(), adicione:

                    // Filtro de data
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _mostrarFiltroData = !_mostrarFiltroData;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.filter_alt,
                                      color: Color(0xFF4A5C6B),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _dataInicio == null
                                            ? 'Filtrar por período'
                                            : '${_dataInicio!.day}/${_dataInicio!.month} - ${_dataFim!.day}/${_dataFim!.month}',
                                        style: TextStyle(
                                          color: _dataInicio == null
                                              ? Colors.grey
                                              : const Color(0xFF4A5C6B),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _mostrarFiltroData
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: const Color(0xFF4A5C6B),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_dataInicio != null)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: _limparFiltroData,
                            ),
                        ],
                      ),
                    ),

                    if (_mostrarFiltroData) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selecionarPeriodo,
                                    icon: const Icon(
                                      Icons.date_range,
                                      size: 16,
                                    ),
                                    label: const Text('Selecionar Período'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF4A5C6B),
                                      side: const BorderSide(
                                        color: Color(0xFF4A5C6B),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_dataInicio != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'De: ${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Até: ${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Filtros
                    _buildFiltros(),

                    // Lista de agendamentos
                    Expanded(
                      child: _agendamentosFiltrados.isEmpty
                          ? _buildEmptyWidget()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _agendamentosFiltrados.length,
                              itemBuilder: (context, index) {
                                final agendamento =
                                    _agendamentosFiltrados[index];
                                return _buildAgendamentoCard(agendamento);
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResumoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF4A5C6B), const Color(0xFF6B7F8F)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A5C6B).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Primeira linha - 3 itens
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildResumoItem(
                  'Pendentes',
                  _getCountPorStatus('PENDENTE').toString(),
                  Icons.pending_actions,
                ),
              ),
              Expanded(
                child: _buildResumoItem(
                  'Confirmados',
                  _getCountPorStatus('CONFIRMADO').toString(),
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildResumoItem(
                  'Em Atendimento',
                  _getCountPorStatus('EM_ANDAMENTO').toString(),
                  Icons.play_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Segunda linha - 3 itens
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildResumoItem(
                  'Concluídos',
                  _getCountPorStatus('CONCLUIDO').toString(),
                  Icons.done_all,
                ),
              ),
              Expanded(
                child: _buildResumoItem(
                  'Cancelados',
                  _getCountPorStatus('CANCELADO').toString(),
                  Icons.cancel,
                ),
              ),
              Expanded(
                child: _buildResumoItem(
                  'Recusados',
                  _getCountPorStatus('RECUSADO').toString(),
                  Icons.cancel,
                ),
              ),
              Expanded(
                flex: 1,
                child: _buildResumoItem(
                  'Total',
                  _agendamentos.length.toString(),
                  Icons.event,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumoItem(String label, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center, // Centralizar texto
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros rápidos de data
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFiltroRapido(
                  'Hoje',
                  () {
                    final hoje = DateTime.now();
                    setState(() {
                      _dataInicio = DateTime(hoje.year, hoje.month, hoje.day);
                      _dataFim = DateTime(
                        hoje.year,
                        hoje.month,
                        hoje.day,
                        23,
                        59,
                        59,
                      );
                    });
                    _carregarAgendamentosComFiltro();
                  },
                  _isFiltroHojeAtivo(), // <-- NOVO PARÂMETRO
                ),
                const SizedBox(width: 8),
                _buildFiltroRapido(
                  'Este Mês',
                  () {
                    final hoje = DateTime.now();
                    setState(() {
                      _dataInicio = DateTime(hoje.year, hoje.month, 1);
                      _dataFim = DateTime(
                        hoje.year,
                        hoje.month + 1,
                        0,
                        23,
                        59,
                        59,
                      );
                    });
                    _carregarAgendamentosComFiltro();
                  },
                  _isFiltroMesAtivo(), // <-- NOVO PARÂMETRO
                ),
                const SizedBox(width: 8),
                _buildFiltroRapido(
                  'Últimos 30 dias',
                  () {
                    final hoje = DateTime.now();
                    final inicio30Dias = hoje.subtract(
                      const Duration(days: 30),
                    );
                    setState(() {
                      _dataInicio = DateTime(
                        inicio30Dias.year,
                        inicio30Dias.month,
                        inicio30Dias.day,
                      );
                      _dataFim = DateTime(
                        hoje.year,
                        hoje.month,
                        hoje.day,
                        23,
                        59,
                        59,
                      );
                    });
                    _carregarAgendamentosComFiltro();
                  },
                  _isFiltro30DiasAtivo(), // <-- NOVO PARÂMETRO
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filtros de status (já existentes)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                final isSelected = _filtroStatus == status;
                final count = _getCountPorStatus(status);
                String statusNom = status;

                if (status == 'EM_ANDAMENTO') {
                  statusNom = 'EM ATENDIMENTO';
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('$statusNom ($count)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filtroStatus = status;
                        _aplicarFiltro();
                      });
                    },
                    selectedColor: const Color(0xFF4A5C6B).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF4A5C6B),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4A5C6B)
                          : Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroRapido(
    String label,
    VoidCallback onPressed,
    bool isSelected,
  ) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF4A5C6B)
              : const Color(0xFF4A5C6B).withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        backgroundColor: isSelected
            ? const Color(0xFF4A5C6B).withOpacity(0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected
              ? const Color(0xFF4A5C6B)
              : const Color(0xFF4A5C6B).withOpacity(0.7),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAgendamentoCard(AgendamentoPrestador agendamento) {
    if (agendamento.statusDescricao == 'EM_ANDAMENTO') {
      agendamento.statusDescricao = 'EM ATENDIMENTO';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetalheAgendamentoPrestadorScreen(agendamento: agendamento),
            ),
          ).then((_) => _carregarAgendamentosComFiltro());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com cliente e status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A5C6B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
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
                          agendamento.clienteNome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                        if (agendamento.clienteTelefone.isNotEmpty)
                          Text(
                            agendamento.clienteTelefone,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
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
                      color: agendamento.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: agendamento.statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      agendamento.statusDescricao,
                      style: TextStyle(
                        fontSize: 10,
                        color: agendamento.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Data e hora
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    agendamento.dataFormatada,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    agendamento.horaServico,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Serviços
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ...agendamento.servicos.take(3).map((item) {
                    final servico = item['servico'] ?? item;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A5C6B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        servico['ServicoNome'] ?? 'Serviço',
                        style: TextStyle(
                          fontSize: 10,
                          color: const Color(0xFF4A5C6B),
                        ),
                      ),
                    );
                  }).toList(),

                  if (agendamento.servicos.length > 3)
                    Text(
                      ' +${agendamento.servicos.length - 3}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Valor total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    'R\$ ${agendamento.valorTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
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
              _errorMessage ?? 'Erro ao carregar agendamentos',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarAgendamentosComFiltro,
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

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4A5C6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy,
                size: 50,
                color: Color(0xFF4A5C6B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum agendamento encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filtroStatus == 'TODOS'
                  ? 'Você ainda não possui agendamentos'
                  : 'Nenhum agendamento com status $_filtroStatus',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
