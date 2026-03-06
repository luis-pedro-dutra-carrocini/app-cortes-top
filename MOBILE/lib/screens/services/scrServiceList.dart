import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modService.dart';
//import '../../models/modUser.dart';
import '../../services/serService.dart';
import '../../providers/proUser.dart';
import 'scrServiceRegister.dart';
import 'scrServiceDetails.dart';

class ListaServicosScreen extends StatefulWidget {
  const ListaServicosScreen({super.key});

  @override
  State<ListaServicosScreen> createState() => _ListaServicosScreenState();
}

class _ListaServicosScreenState extends State<ListaServicosScreen> {
  final ServicoService _servicoService = ServicoService();
  List<Servico> _servicos = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _filtroAtivos = true; // true = mostrar ativos, false = mostrar todos

  @override
  void initState() {
    super.initState();
    _carregarServicos();
  }

  Future<void> _carregarServicos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      final usuario = usuarioProvider.usuario;
      final token = usuarioProvider.token;

      if (usuario == null || token == null) return;

      final result = await _servicoService.listarMeusServicos(usuario.id!, token);

      if (mounted) {
        if (result['success']) {
          setState(() {
            _servicos = result['data'];
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
          _errorMessage = 'Erro ao carregar serviços: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Servico> get _servicosFiltrados {
    if (_filtroAtivos) {
      return _servicos.where((s) => s.ativo).toList();
    }
    return _servicos;
  }

  int get _totalAtivos => _servicos.where((s) => s.ativo).length;
  int get _totalInativos => _servicos.where((s) => !s.ativo).length;

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = Provider.of<UsuarioProvider>(context);
    final usuario = usuarioProvider.usuario;

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
          'Meus Serviços',
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
            onPressed: _carregarServicos,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarServicos,
          color: const Color(0xFF4A5C6B),
          child: Column(
            children: [
              // Card de resumo
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
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
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A5C6B).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResumoItem('Total', _servicos.length.toString(), Icons.list),
                    _buildResumoItem('Ativos', _totalAtivos.toString(), Icons.check_circle),
                    _buildResumoItem('Inativos', _totalInativos.toString(), Icons.cancel),
                  ],
                ),
              ),

              // Filtro
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFiltroBotao(
                        label: 'Ativos',
                        isSelected: _filtroAtivos,
                        onTap: () {
                          setState(() {
                            _filtroAtivos = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFiltroBotao(
                        label: 'Todos',
                        isSelected: !_filtroAtivos,
                        onTap: () {
                          setState(() {
                            _filtroAtivos = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Lista de serviços
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A5C6B)))
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : _servicosFiltrados.isEmpty
                            ? _buildEmptyWidget()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _servicosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final servico = _servicosFiltrados[index];
                                  return _buildServicoCard(servico);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CadastroServicoScreen(
                prestadorId: usuario!.id!,
                token: usuarioProvider.token!,
              ),
            ),
          ).then((_) => _carregarServicos());
        },
        backgroundColor: const Color(0xFF4A5C6B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildResumoItem(String label, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroBotao({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A5C6B) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF4A5C6B),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF4A5C6B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicoCard(Servico servico) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesServicoScreen(
                servico: servico,
              ),
            ),
          ).then((_) => _carregarServicos());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: !servico.ativo
                ? Border.all(color: Colors.grey.shade300)
                : null,
          ),
          child: Row(
            children: [
              // Ícone do serviço
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (servico.ativo 
                      ? const Color(0xFF4A5C6B) 
                      : Colors.grey).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.build_circle,
                  size: 30,
                  color: servico.ativo 
                      ? const Color(0xFF4A5C6B) 
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),

              // Informações do serviço
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            servico.nome,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: servico.ativo 
                                  ? const Color(0xFF4A5C6B) 
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                        if (!servico.ativo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Inativo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (servico.descricao != null && servico.descricao!.isNotEmpty)
                      Text(
                        servico.descricao!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${servico.tempoMedio} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.attach_money,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          servico.precoAtual != null
                              ? 'R\$ ${servico.precoAtual!.toStringAsFixed(2)}'
                              : 'Sem preço',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: servico.precoAtual != null 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                            color: servico.precoAtual != null 
                                ? Colors.green.shade700 
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Seta de navegação
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: servico.ativo 
                    ? const Color(0xFF4A5C6B) 
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
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
            _errorMessage ?? 'Erro ao carregar serviços',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _carregarServicos,
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
              Icons.build_circle,
              size: 50,
              color: Color(0xFF4A5C6B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum serviço encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5C6B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clique no botão + para cadastrar\nseu primeiro serviço',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}