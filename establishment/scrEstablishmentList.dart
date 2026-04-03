import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/serEstablishment.dart';
import '../../providers/proUser.dart';
import 'scrEstablishmentForm.dart';
import 'scrEstablishmentDetail.dart';
import '../enterprise/scrAvailability.dart';
import '../enterprise/scrScheduling.dart';

class ListaEstabelecimentosScreen extends StatefulWidget {
  const ListaEstabelecimentosScreen({super.key});

  @override
  State<ListaEstabelecimentosScreen> createState() =>
      _ListaEstabelecimentosScreenState();
}

class _ListaEstabelecimentosScreenState
    extends State<ListaEstabelecimentosScreen> {
  final EstabelecimentoService _service = EstabelecimentoService();
  List<dynamic> _estabelecimentos = [];
  bool _isLoading = true;
  String? _selectedStatus;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _carregarEstabelecimentos();
  }

  Future<void> _carregarEstabelecimentos() async {
    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.listarEstabelecimentos(
        token: token,
        page: _currentPage,
        limit: _limit,
        status: _selectedStatus,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _estabelecimentos = result['data'];
            _totalPages = result['pagination']?['pages'] ?? 1;
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ATIVO':
        return Colors.green;
      case 'INATIVO':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ATIVO':
        return 'Ativo';
      case 'INATIVO':
        return 'Inativo';
      default:
        return status;
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
          'Meus Estabelecimentos',
          style: TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4A5C6B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EstabelecimentoFormScreen(),
                ),
              ).then((_) => _carregarEstabelecimentos());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      const DropdownMenuItem(
                        value: 'ATIVO',
                        child: Text('Ativos'),
                      ),
                      const DropdownMenuItem(
                        value: 'INATIVO',
                        child: Text('Inativos'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                        _currentPage = 1;
                      });
                      _carregarEstabelecimentos();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
                  )
                : _estabelecimentos.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _estabelecimentos.length,
                    itemBuilder: (context, index) {
                      final est = _estabelecimentos[index];
                      return _buildEstabelecimentoCard(est);
                    },
                  ),
          ),

          // Paginação
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _carregarEstabelecimentos();
                          }
                        : null,
                  ),
                  Text('Página $_currentPage de $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _carregarEstabelecimentos();
                          }
                        : null,
                  ),
                ],
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
          Icon(
            Icons.store_mall_directory_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum estabelecimento cadastrado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique no + para adicionar',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEstabelecimentoCard(dynamic est) {
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
                  EstabelecimentoDetailScreen(estabelecimentoId: est.id),
            ),
          ).then((_) => _carregarEstabelecimentos());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A5C6B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Color(0xFF4A5C6B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          est.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          est.telefone,
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
                      color: _getStatusColor(est.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(est.status),
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(est.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${est.rua ?? ""}, ${est.numero ?? ""} - ${est.bairro ?? ""}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Disponibilidades de ${est.totalUsuarios ?? 0} prestador(es)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.event_available,
                      color: Color(0xFF4A5C6B),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisponibilidadesEmpresaScreen(
                            estabelecimentoId: est.id,
                            estabelecimentoNome: est.nome,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.event_note_sharp, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Acompanhar agendamentos',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.event_outlined,
                      color: Color(0xFF4A5C6B),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AgendamentosEmpresaScreen(
                            estabelecimentoId: est.id,
                            estabelecimentoNome: est.nome,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
