import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/serDashboardEmpresa.dart';
import '../../../providers/proUser.dart';

class DashboardEmpresaScreen extends StatefulWidget {
  const DashboardEmpresaScreen({super.key});

  @override
  State<DashboardEmpresaScreen> createState() => _DashboardEmpresaScreenState();
}

class _DashboardEmpresaScreenState extends State<DashboardEmpresaScreen> {
  final DashboardEmpresaService _dashboardService = DashboardEmpresaService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String _periodoTipo = 'mes'; // 'ano', 'mes', 'dia'
  int? _estabelecimentoSelecionado;
  String _errorMessage = '';

  // Opções de período
  final Map<String, String> _periodos = {
    'dia': 'Hoje',
    'mes': 'Este Mês',
    'ano': 'Este Ano',
  };

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
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

      final result = await _dashboardService.obterDashboard(
        token: token,
        tipo: _periodoTipo,
        estabelecimentoId: _estabelecimentoSelecionado,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _dashboardData = result['data'];
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
        _errorMessage = 'Erro ao carregar dashboard: $e';
        _isLoading = false;
      });
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
          'Dashboard Empresarial',
          style: TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // Seletor de período
          PopupMenuButton<String>(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF4A5C6B)),
            onSelected: (value) {
              setState(() {
                _periodoTipo = value;
              });
              _carregarDashboard();
            },
            itemBuilder: (context) => _periodos.entries.map((entry) {
              return PopupMenuItem(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
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
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarDashboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5C6B),
                        ),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtro de estabelecimento e período
                      _buildFiltros(),

                      const SizedBox(height: 20),

                      // Cards de resumo
                      _buildResumoCards(),

                      const SizedBox(height: 24),

                      // Gráfico de faturamento
                      _buildGraficoFaturamento(),

                      const SizedBox(height: 24),

                      // Serviços mais solicitados
                      _buildServicosMaisSolicitados(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFiltros() {
    final estabelecimentos = _dashboardData?['estabelecimentos'] ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, color: Color(0xFF4A5C6B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: _estabelecimentoSelecionado,
                hint: const Text('Todos os estabelecimentos'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos os estabelecimentos'),
                  ),
                  ...estabelecimentos.map<DropdownMenuItem<int?>>((est) {
                    return DropdownMenuItem<int?>(
                      value: est['id'],
                      child: Text(
                        est['nome'] ?? 'Sem nome',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _estabelecimentoSelecionado = value;
                  });
                  _carregarDashboard();
                },
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF4A5C6B)),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4A5C6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _periodos[_periodoTipo] ?? 'Este Mês',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCards() {
    final resumo = _dashboardData?['resumo'];
    if (resumo == null) return const SizedBox.shrink();

    final agendamentos = resumo['agendamentos'] ?? {};
    final faturamento = resumo['faturamento'] ?? {};

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _buildResumoCard(
          titulo: 'Agendamentos',
          valor: '${agendamentos['total'] ?? 0}',
          detalhes: [
            'Pendentes: ${agendamentos['pendentes'] ?? 0}',
            'Confirmados: ${agendamentos['confirmados'] ?? 0}',
            'Concluídos: ${agendamentos['concluidos'] ?? 0}',
            'Cancelados: ${agendamentos['cancelados'] ?? 0}',
            'Recusados: ${agendamentos['recusados'] ?? 0}',
          ],
          icone: Icons.calendar_today,
          cor: const Color(0xFF4A5C6B),
        ),
        _buildResumoCard(
          titulo: 'Taxa de Conclusão',
          valor: _calcularTaxaConclusao(agendamentos),
          detalhes: [
            'Concluídos: ${agendamentos['concluidos'] ?? 0}',
            'Total: ${agendamentos['total'] ?? 0}'
          ],
          icone: Icons.percent,
          cor: Colors.orange,
        ),
        _buildResumoCard(
          titulo: 'Faturamento Realizado',
          valor: _formatarMoeda(faturamento['realizado'] ?? 0),
          detalhes: [
            'Previsto: ${_formatarMoeda(faturamento['previsto'] ?? 0)}',
            'Total: ${_formatarMoeda(faturamento['total'] ?? 0)}',
          ],
          icone: Icons.attach_money,
          cor: Colors.green,
        ),
        _buildResumoCard(
          titulo: 'Agendamentos em Andamento',
          valor: '${agendamentos['emAndamento'] ?? 0}',
          detalhes: [],
          icone: Icons.play_circle,
          cor: Colors.blue,
        ),
      ],
    );
  }

  String _calcularTaxaConclusao(Map<String, dynamic> agendamentos) {
    final total = agendamentos['total'] ?? 0;
    final concluidos = agendamentos['concluidos'] ?? 0;
    if (total == 0) return '0%';
    return '${((concluidos / total) * 100).toInt()}%';
  }

  Widget _buildResumoCard({
    required String titulo,
    required String valor,
    required List<String> detalhes,
    required IconData icone,
    required Color cor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 16, color: cor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5C6B),
            ),
          ),
          if (detalhes.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...detalhes.map(
              (detalhe) => Text(
                detalhe,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGraficoFaturamento() {
    final detalhamento = _dashboardData?['detalhamento'];
    final faturamentoPorPeriodo = detalhamento?['faturamentoPorPeriodo'] ?? [];

    if (faturamentoPorPeriodo.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Nenhum dado de faturamento no período',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    double maxValor = 0.0;
    for (var item in faturamentoPorPeriodo) {
      final valor = (item['valor'] ?? 0).toDouble();
      if (valor > maxValor) {
        maxValor = valor;
      }
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Evolução do Faturamento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: (faturamentoPorPeriodo.length * 50).clamp(300, double.infinity).toDouble(),
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxValor * 1.1,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              'R\$ ${value.toInt()}',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < faturamentoPorPeriodo.length) {
                              return Transform.rotate(
                                angle: _periodoTipo == 'mes' ? -0.5 : 0,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    faturamentoPorPeriodo[index]['periodo'] ?? '',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(faturamentoPorPeriodo.length, (index) {
                      final valor = (faturamentoPorPeriodo[index]['valor'] ?? 0).toDouble();
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: valor,
                            color: const Color(0xFF4A5C6B),
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicosMaisSolicitados() {
    final detalhamento = _dashboardData?['detalhamento'];
    final servicos = detalhamento?['servicosMaisSolicitados'] ?? [];

    if (servicos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Serviços Mais Solicitados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ),
          const Divider(height: 1),
          ...servicos.map((servico) => _buildServicoTile(servico)),
        ],
      ),
    );
  }

  Widget _buildServicoTile(Map<String, dynamic> servico) {
    final quantidade = servico['quantidade'] ?? 0;
    final valorTotal = servico['valorTotal'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              size: 16,
              color: Color(0xFF4A5C6B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servico['nome'] ?? 'Serviço',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5C6B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$quantidade vez(es)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _formatarMoeda(valorTotal),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}