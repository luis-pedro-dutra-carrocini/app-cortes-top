import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/modAvailability.dart';
import '../../../services/serAvailabilityEmpresa.dart';
import '../../../providers/proUser.dart';
import 'package:http/http.dart' as http;
import '../../config/conApi.dart';
import 'dart:convert';

class DisponibilidadesEmpresaScreen extends StatefulWidget {
  final int estabelecimentoId;
  final String estabelecimentoNome;

  const DisponibilidadesEmpresaScreen({
    super.key,
    required this.estabelecimentoId,
    required this.estabelecimentoNome,
  });

  @override
  State<DisponibilidadesEmpresaScreen> createState() =>
      _DisponibilidadesEmpresaScreenState();
}

class _DisponibilidadesEmpresaScreenState
    extends State<DisponibilidadesEmpresaScreen> {
  final AvailabilityEmpresaService _service = AvailabilityEmpresaService();
  List<Disponibilidade> _disponibilidades = [];
  List<Map<String, dynamic>> _disponibilidadesAgrupadas = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Filtros
  DateTime? _dataInicio;
  DateTime? _dataFim;
  int? _prestadorSelecionado;
  List<Map<String, dynamic>> _prestadores = [];

  @override
  void initState() {
    super.initState();
    _carregarDisponibilidades();
    _carregarPrestadores();
  }

  Future<void> _carregarDisponibilidades() async {
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

      final result = await _service.listarDisponibilidadesPorEstabelecimento(
        estabelecimentoId: widget.estabelecimentoId,
        token: token,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _disponibilidades = result['data'] ?? [];
            // Agrupar manualmente os dados por data
            _disponibilidadesAgrupadas = _agruparPorData(_disponibilidades);
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
        _errorMessage = 'Erro: $e';
        _isLoading = false;
      });
    }
  }

  // Método para agrupar disponibilidades por data
  List<Map<String, dynamic>> _agruparPorData(
    List<Disponibilidade> disponibilidades,
  ) {
    final Map<String, Map<String, dynamic>> agrupado = {};
    final diasSemana = [
      'Domingo',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
    ];

    for (var disp in disponibilidades) {
      final dataKey = disp.data.toIso8601String().split('T')[0];

      if (!agrupado.containsKey(dataKey)) {
        final diaSemana = disp.data.weekday % 7; // Ajuste para domingo=0
        agrupado[dataKey] = {
          'data': dataKey,
          'dataFormatada':
              '${disp.data.day.toString().padLeft(2, '0')}/${disp.data.month.toString().padLeft(2, '0')}/${disp.data.year}',
          'diaSemana': diaSemana,
          'diaSemanaDescricao': diasSemana[diaSemana],
          'disponibilidades': [],
        };
      }
      agrupado[dataKey]!['disponibilidades'].add(disp);
    }

    return agrupado.values.toList();
  }

  Future<void> _carregarPrestadores() async {
    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      // Buscar prestadores vinculados ao estabelecimento
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}estabelecimento/${widget.estabelecimentoId}/usuarios',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(
        '${ApiConfig.baseUrl}estabelecimento/${widget.estabelecimentoId}/usuarios',
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _prestadores = (data['data'] as List)
              .map((p) => {'id': p['UsuarioId'], 'nome': p['UsuarioNome']})
              .toList();
        });
      }
    } catch (e) {
      print('Erro ao carregar prestadores: $e');
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

  Color _getStatusColor(bool status) {
    return status ? Colors.green : Colors.red;
  }

  String _getStatusText(bool status) {
    return status ? 'Disponível' : 'Reservado';
  }

  //(removido-limpeza)
  /*
  Future<void> _selecionarPeriodo() async {
    final dateRange = await showDateRangePicker(
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

    if (dateRange != null) {
      setState(() {
        _dataInicio = dateRange.start;
        _dataFim = dateRange.end;
      });
      _carregarDisponibilidades();
    }
  }
  */

  void _limparFiltros() {
    setState(() {
      _dataInicio = null;
      _dataFim = null;
      _prestadorSelecionado = null;
    });
    _carregarDisponibilidades();
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
        title: Text(
          'Disponibilidades - ${widget.estabelecimentoNome}',
          style: const TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF4A5C6B)),
            onPressed: _mostrarFiltros,
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
                    onPressed: _carregarDisponibilidades,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A5C6B),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : _disponibilidadesAgrupadas.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _disponibilidadesAgrupadas.length,
              itemBuilder: (context, index) {
                final grupo = _disponibilidadesAgrupadas[index];
                return _buildDataCard(grupo);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhuma disponibilidade encontrada',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione um período para visualizar',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(Map<String, dynamic> grupo) {
    final data = grupo['dataFormatada'];
    final diaSemana = grupo['diaSemanaDescricao'];
    final disponibilidades = grupo['disponibilidades'] as List;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A5C6B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF4A5C6B),
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text(
                data,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5C6B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  diaSemana,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${disponibilidades.length} horário(s)',
            style: const TextStyle(fontSize: 12),
          ),
          children: disponibilidades
              .map((disp) => _buildHorarioTile(disp))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildHorarioTile(Disponibilidade disponibilidade) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: disponibilidade.status
            ? const Color(0xFFF5F7FA)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: disponibilidade.status
              ? Colors.grey.shade200
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: disponibilidade.status
                  ? const Color(0xFF4A5C6B).withOpacity(0.1)
                  : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time,
              size: 16,
              color: disponibilidade.status
                  ? const Color(0xFF4A5C6B)
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${disponibilidade.horaInicio} - ${disponibilidade.horaFim}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: disponibilidade.status
                        ? const Color(0xFF4A5C6B)
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Prestador: ${disponibilidade.prestadorNome}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(disponibilidade.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(disponibilidade.status),
              style: TextStyle(
                fontSize: 10,
                color: _getStatusColor(disponibilidade.status),
                fontWeight: FontWeight.bold,
              ),
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
        DateTime? dataInicioTemp = _dataInicio;
        DateTime? dataFimTemp = _dataFim;
        int? prestadorTemp = _prestadorSelecionado;

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar Disponibilidades',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Período
                  const Text(
                    'Período',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dataInicioTemp ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
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
                            if (date != null) {
                              setStateSheet(() {
                                dataInicioTemp = date;
                              });
                            }
                          },
                          child: Text(
                            dataInicioTemp != null
                                ? '${dataInicioTemp!.day}/${dataInicioTemp!.month}/${dataInicioTemp!.year}'
                                : 'Data Início',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dataFimTemp ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
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
                            if (date != null) {
                              setStateSheet(() {
                                dataFimTemp = date;
                              });
                            }
                          },
                          child: Text(
                            dataFimTemp != null
                                ? '${dataFimTemp!.day}/${dataFimTemp!.month}/${dataFimTemp!.year}'
                                : 'Data Fim',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Prestador
                  if (_prestadores.isNotEmpty) ...[
                    const Text(
                      'Prestador',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      value: prestadorTemp,
                      hint: const Text('Todos os prestadores'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todos os prestadores'),
                        ),
                        ..._prestadores.map((p) {
                          return DropdownMenuItem<int?>(
                            value: p['id'],
                            child: Text(p['nome'] ?? ''),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setStateSheet(() {
                          prestadorTemp = value;
                        });
                      },
                    ),
                  ],

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
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _dataInicio = dataInicioTemp;
                              _dataFim = dataFimTemp;
                              _prestadorSelecionado = prestadorTemp;
                            });
                            Navigator.pop(context);
                            _carregarDisponibilidades();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A5C6B),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                  if (_dataInicio != null ||
                      _dataFim != null ||
                      _prestadorSelecionado != null)
                    TextButton(
                      onPressed: _limparFiltros,
                      child: const Text('Limpar filtros'),
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
