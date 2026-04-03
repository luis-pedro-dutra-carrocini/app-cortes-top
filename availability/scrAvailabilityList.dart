import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:flutter_localizations/flutter_localizations.dart';
import '../../models/modAvailability.dart';
import '../../services/serAvailability.dart';
import '../../providers/proUser.dart';
import 'scrAvailabilityRegister.dart';
import 'scrAvailabilityEdit.dart';

class ListaDisponibilidadeScreen extends StatefulWidget {
  const ListaDisponibilidadeScreen({super.key});

  @override
  State<ListaDisponibilidadeScreen> createState() =>
      _ListaDisponibilidadeScreenState();
}

class _ListaDisponibilidadeScreenState
    extends State<ListaDisponibilidadeScreen> {
  final DisponibilidadeService _disponibilidadeService =
      DisponibilidadeService();
  List<DisponibilidadeAgrupada> _disponibilidadesAgrupadas = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Controlador para o filtro de data
  DateTime _dataInicial = DateTime.now();
  DateTime _dataFinal = DateTime.now().add(const Duration(days: 30));

  bool _isDataFutura(DateTime dataDisponibilidade) {
    final hoje = DateTime.now();
    final dataComparar = DateTime(
      dataDisponibilidade.year,
      dataDisponibilidade.month,
      dataDisponibilidade.day,
    );
    final hojeComparar = DateTime(hoje.year, hoje.month, hoje.day);

    // Retorna true se a data for maior que hoje (futura)
    return dataComparar.isAfter(hojeComparar);
  }

  @override
  void initState() {
    super.initState();
    _carregarDisponibilidades();
  }

  Future<void> _carregarDisponibilidades() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final usuario = usuarioProvider.usuario;
      final token = usuarioProvider.token;
      final dataSelecionadaFim = _dataFinal;
      final dataSelecionadaInicio = _dataInicial;

      if (usuario == null || token == null) return;

      final result = await _disponibilidadeService.listarMinhasDisponibilidades(
        usuario.id!,
        token,
        dataInicio: dataSelecionadaInicio, // DateTime do período inicial
        dataFim: dataSelecionadaFim, // DateTime do período final
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            // Tentar os dois nomes possíveis
            _disponibilidadesAgrupadas =
                result['agrupadoPorData'] ?? result['agrupadoPorDia'] ?? [];
            _isLoading = false;
          });

          print(
            'Disponibilidades carregadas: ${_disponibilidadesAgrupadas.length}',
          );
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
          _errorMessage = 'Erro ao carregar disponibilidades: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _abrirCadastroDisponibilidade({DateTime? dataInicial}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CadastroDisponibilidadeScreen(dataInicial: dataInicial),
      ),
    ).then((_) => _carregarDisponibilidades());
  }

  void _abrirEdicaoDisponibilidade(Disponibilidade disponibilidade) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditarDisponibilidadeScreen(disponibilidade: disponibilidade),
      ),
    ).then((_) => _carregarDisponibilidades());
  }

  Future<void> _selecionarPeriodo() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _dataInicial, end: _dataFinal),
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
        _dataInicial = picked.start;
        _dataFinal = picked.end;
      });
      _carregarDisponibilidades(); // Recarregar com novo período
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
          'Minha Disponibilidade',
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
            onPressed: _carregarDisponibilidades,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarDisponibilidades,
          color: const Color(0xFF4A5C6B),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
                )
              : _errorMessage != null
              ? _buildErrorWidget()
              : _buildContent(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirCadastroDisponibilidade(),
        backgroundColor: const Color(0xFF4A5C6B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Filtro de período
        _buildFiltroPeriodo(),

        Expanded(
          child: _disponibilidadesAgrupadas.isEmpty
              ? _buildEmptyWidget()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _disponibilidadesAgrupadas.length,
                  itemBuilder: (context, index) {
                    final grupo = _disponibilidadesAgrupadas[index];
                    return _buildDataCard(grupo);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltroPeriodo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: _selecionarPeriodo,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF4A5C6B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_dataInicial.day}/${_dataInicial.month} - ${_dataFinal.day}/${_dataFinal.month}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF4A5C6B)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF4A5C6B)),
            onPressed: _selecionarPeriodo,
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(DisponibilidadeAgrupada grupo) {
    // Criar um ValueNotifier para controlar o estado de expansão
    final expansionNotifier = ValueNotifier<bool>(false);
    final data = DateTime.parse(grupo.data);

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
                grupo.dataFormatada,
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
                  grupo.diaSemanaAbreviado,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${grupo.disponibilidades.length} horário(s)',
            style: const TextStyle(fontSize: 12),
          ),
          // Controlar o estado de expansão
          onExpansionChanged: (expanded) {
            expansionNotifier.value = expanded;
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDataFutura(data)) ...[
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Color(0xFF4A5C6B),
                    size: 20,
                  ),
                  onPressed: () {
                    final data = DateTime.parse(grupo.data);
                    _abrirCadastroDisponibilidade(dataInicial: data);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
              const SizedBox(width: 8),
              // Usar ValueListenableBuilder para atualizar o ícone
              ValueListenableBuilder<bool>(
                valueListenable: expansionNotifier,
                builder: (context, isExpanded, child) {
                  return Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: grupo.disponibilidades.isNotEmpty
                        ? const Color(0xFF4A5C6B)
                        : Colors.grey,
                    size: 24,
                  );
                },
              ),
            ],
          ),
          children: grupo.disponibilidades.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Nenhum horário cadastrado para esta data',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  ),
                ]
              : grupo.disponibilidades
                    .map((disp) => _buildHorarioTile(disp))
                    .toList(),
        ),
      ),
    );
  }

  Widget _buildHorarioTile(Disponibilidade disponibilidade) {
    // Verifica se está vinculado a um estabelecimento
    final bool temEstabelecimento = disponibilidade.estabelecimentoId != null;
    final String nomeEstabelecimento =
        disponibilidade.estabelecimentoNome ?? 'Estabelecimento';

    // Define a cor de fundo baseada no status e se tem estabelecimento
    Color getBackgroundColor() {
      if (!disponibilidade.status) return Colors.grey.shade100;
      if (temEstabelecimento)
        return const Color(0xFFE8F0FE); // Azul claro para estabelecimento
      return const Color(0xFFF5F7FA); // Cor padrão
    }

    // Define a cor da borda baseada no status e se tem estabelecimento
    Color getBorderColor() {
      if (!disponibilidade.status) return Colors.grey.shade300;
      if (temEstabelecimento) return Colors.blue.shade200;
      return Colors.grey.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: getBorderColor()),
      ),
      child: Row(
        children: [
          // Ícone com cor diferenciada se for de estabelecimento
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: !disponibilidade.status
                  ? Colors.grey.shade200
                  : temEstabelecimento
                  ? Colors.blue.withOpacity(0.1)
                  : const Color(0xFF4A5C6B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              temEstabelecimento ? Icons.business : Icons.access_time,
              size: 16,
              color: !disponibilidade.status
                  ? Colors.grey
                  : temEstabelecimento
                  ? const Color.fromARGB(255, 143, 191, 238)
                  : const Color(0xFF4A5C6B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disponibilidade.horarioFormatado,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: !disponibilidade.status
                        ? Colors.grey.shade600
                        : temEstabelecimento
                        ? Colors.blue.shade800
                        : const Color(0xFF4A5C6B),
                  ),
                ),
                if (temEstabelecimento && disponibilidade.status) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 10,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          nomeEstabelecimento,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (!disponibilidade.status) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Indisponível',
                    style: TextStyle(fontSize: 10, color: Colors.red.shade300),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isDataFutura(disponibilidade.data)) ...[
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: disponibilidade.status
                        ? const Color(0xFF4A5C6B)
                        : Colors.grey.shade400,
                    size: 18,
                  ),
                  onPressed: disponibilidade.status
                      ? () => _abrirEdicaoDisponibilidade(disponibilidade)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: disponibilidade.status
                      ? Colors.red
                      : Colors.grey.shade400,
                  size: 18,
                ),
                onPressed: disponibilidade.status
                    ? () => _mostrarDialogExcluir(disponibilidade)
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarDialogExcluir(Disponibilidade disponibilidade) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 50,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Excluir Horário',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Text(
              'Tem certeza que deseja excluir este horário?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    disponibilidade.dataFormatada,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    disponibilidade.horarioFormatado,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Esta ação não poderá ser desfeita.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _excluirDisponibilidade(disponibilidade.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirDisponibilidade(int disponibilidadeId) async {
    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _disponibilidadeService.excluirDisponibilidade(
        disponibilidadeId,
        token,
      );

      if (mounted) {
        if (result['success']) {
          _carregarDisponibilidades();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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
              _errorMessage ?? 'Erro ao carregar disponibilidades',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarDisponibilidades,
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
              Icons.event_available,
              size: 50,
              color: Color(0xFF4A5C6B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma disponibilidade encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5C6B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clique no botão + para adicionar\nseus horários disponíveis',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
