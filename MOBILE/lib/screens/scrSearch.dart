import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/serSearch.dart';
import '../providers/proUser.dart';
import '../services/serScheduling.dart';
import 'scheduling/scrSchedulingNew.dart';

class PesquisaScreen extends StatefulWidget {
  const PesquisaScreen({super.key});

  @override
  State<PesquisaScreen> createState() => _PesquisaScreenState();
}

class _PesquisaScreenState extends State<PesquisaScreen> {
  final PesquisaService _pesquisaService = PesquisaService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _resultados = [];
  bool _isLoading = false;
  String _selectedType = 'todos';
  final Set<int> _expandedItems = {};
  String _uuid = '';

  final AgendamentoService _agendamentoService = AgendamentoService();

  dynamic _empresaSelecionada;

  final Map<String, String> _tipos = {
    'todos': 'Todos',
    'PRESTADOR': 'Prestadores',
    'EMPRESA': 'Empresas',
    'ESTABELECIMENTO': 'Estabelecimentos',
  };

  @override
  void initState() {
    super.initState();
    //_searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    //_searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    //_debounce?.cancel();
    super.dispose();
  }

  /*
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _realizarPesquisa();
    });
  }
  */

  Future<void> _realizarPesquisa() async {
    final termo = _searchController.text.trim();
    if (termo.isEmpty) {
      setState(() {
        _resultados = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;
      final usuario = usuarioProvider.usuario;

      if (token == null) return;

      // Verificar se é cliente
      if (usuario?.tipo != 'CLIENTE') {
        _mostrarSnackBar('Apenas clientes podem realizar buscas', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final result = await _pesquisaService.pesquisarTodos(
        token: token,
        termo: termo,
        tipo: _selectedType == 'todos' ? null : _selectedType,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _resultados = result['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  void _iniciarAgendamento(dynamic item) async {
    final tipo = item['tipo'];

    final usuarioProvider = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    );
    final token = usuarioProvider.token;

    if (token == null) return;

    final result = await _agendamentoService.iniciarAgendamento(
      token: token,
      tela: 'MOBILE_PESQUISA',
    );

    //print('AQUIIIIIIIIIIIIIIIIIIII11111:  ' + mounted.toString() + ' - ' + result.toString());
    if (mounted && result['success']) {
      _uuid = result['uuid'].toString();
      //print('AQUIIIIIIIIIIIIIIIIIIII:  ' + _uuid);
      if (tipo == 'PRESTADOR') {
        // Navegar para tela de agendamento com prestador
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NovoAgendamentoScreen(
              prestadorId: item['id'],
              prestadorNome: item['nome'],
              uuid: _uuid,
            ),
          ),
        );
      } else if (tipo == 'ESTABELECIMENTO') {
        // Navegar para tela de agendamento com estabelecimento
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NovoAgendamentoScreen(
              estabelecimentoId: item['id'],
              estabelecimentoNome: item['nome'],
              empresaId: item['empresa']?['id'],
              uuid: _uuid,
            ),
          ),
        );
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

  String _formatarTelefone(String telefone) {
    if (telefone.length == 11) {
      return '(${telefone.substring(0, 2)}) ${telefone.substring(2, 7)}-${telefone.substring(7)}';
    } else if (telefone.length == 10) {
      return '(${telefone.substring(0, 2)}) ${telefone.substring(2, 6)}-${telefone.substring(6)}';
    }
    return telefone;
  }

  IconData _getIconForType(String tipo) {
    switch (tipo) {
      case 'PRESTADOR':
        return Icons.build;
      case 'EMPRESA':
        return Icons.business;
      case 'ESTABELECIMENTO':
        return Icons.store;
      default:
        return Icons.search;
    }
  }

  Color _getColorForType(String tipo) {
    switch (tipo) {
      case 'PRESTADOR':
        return const Color(0xFF4A5C6B);
      case 'EMPRESA':
        return Colors.blue.shade700;
      case 'ESTABELECIMENTO':
        return Colors.green.shade700;
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
          'Pesquisar',
          style: TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Campo de pesquisa
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nome ou telefone...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) =>
                          _realizarPesquisa(), // Pesquisa ao pressionar Enter
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFF4A5C6B)),
                    onPressed: _realizarPesquisa,
                    tooltip: 'Pesquisar',
                  ),
                ],
              ),
            ),
          ),

          // Filtro de tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _tipos.entries.map((entry) {
                final isSelected = _selectedType == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = entry.key;
                      });
                      _realizarPesquisa();
                    },
                    selectedColor: const Color(0xFF4A5C6B).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF4A5C6B),
                  ),
                );
              }).toList(),
            ),
          ),

          // Resultados
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
                  )
                : _resultados.isEmpty
                ? _searchController.text.isEmpty
                      ? _buildEmptyState()
                      : _buildNoResultsState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _resultados.length,
                    itemBuilder: (context, index) {
                      final item = _resultados[index];
                      return _buildResultCard(item, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Digite algo para buscar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Busque por prestadores, empresas ou estabelecimentos',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhum resultado encontrado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente outro termo de busca',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(dynamic item, int index) {
    final tipo = item['tipo'];
    final cor = _getColorForType(tipo);
    final icone = _getIconForType(tipo);
    final isExpanded = _expandedItems.contains(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Cabeçalho (sempre visível)
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icone, color: cor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nome'] ?? 'Nome não informado',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (item['telefone'] != null)
                          Text(
                            _formatarTelefone(item['telefone']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        if (tipo == 'ESTABELECIMENTO' &&
                            item['empresa'] != null)
                          Text(
                            item['empresa']['nome'],
                            style: TextStyle(
                              fontSize: 12,
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
                      color: cor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _tipos[tipo] ?? tipo,
                      style: TextStyle(
                        fontSize: 10,
                        color: cor,
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
                  // Detalhes comuns
                  if (item['enderecoCompleto'] != null)
                    _buildDetailRow(
                      Icons.location_on,
                      'Endereço',
                      '${item['enderecoCompleto']}',
                    ),

                  if (tipo == 'PRESTADOR') ...[
                    ElevatedButton.icon(
                      onPressed: () => _iniciarAgendamento(item),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Iniciar Agendamento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A5C6B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],

                  if (tipo == 'ESTABELECIMENTO') ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _iniciarAgendamento(item),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Iniciar Agendamento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A5C6B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],

                  if (tipo == 'EMPRESA') ...[
                    if (item['descricao'] != null &&
                        item['descricao'].isNotEmpty)
                      _buildDetailRow(
                        Icons.description,
                        'Descrição',
                        item['descricao'],
                      ),
                    const SizedBox(height: 12),
                    // TODO: Buscar estabelecimentos da empresa
                    const Text(
                      'Estabelecimentos vinculados:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildEstabelecimentosList(item['id']),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4A5C6B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstabelecimentosList(int empresaId) {
    return FutureBuilder<List<dynamic>>(
      future: _buscarEstabelecimentosDaEmpresa(empresaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Nenhum estabelecimento vinculado',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          );
        }

        return Column(
          children: snapshot.data!.map((est) {
            // Adicionar os campos necessários antes de passar para o item
            final estabelecimentoCompleto = {
              ...est,
              'tipo': 'ESTABELECIMENTO',
              'empresa': {
                'id': empresaId,
                'nome': _empresaSelecionada?['nome'] ?? 'Empresa',
              },
            };
            return _buildEstabelecimentoItem(estabelecimentoCompleto);
          }).toList(),
        );
      },
    );
  }

  Future<List<dynamic>> _buscarEstabelecimentosDaEmpresa(int empresaId) async {
    // Implementar busca de estabelecimentos da empresa
    final usuarioProvider = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    );
    final token = usuarioProvider.token;

    if (token == null) return [];

    final result = await _pesquisaService.buscarEstabelecimentosPorEmpresa(
      token: token,
      empresaId: empresaId,
    );

    if (result['success']) {
      return result['data'] ?? [];
    }
    return [];
  }

  Widget _buildEstabelecimentoItem(dynamic estabelecimento) {
    estabelecimento['tipo'] = 'ESTABELECIMENTO';
    //print(estabelecimento);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.store, size: 16, color: Color(0xFF4A5C6B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estabelecimento['nome'] ?? 'Sem nome',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4A5C6B),
                  ),
                ),
                if (estabelecimento['telefone'] != null)
                  Text(
                    _formatarTelefone(estabelecimento['telefone']),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _iniciarAgendamento(estabelecimento),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5C6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Agendar', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
