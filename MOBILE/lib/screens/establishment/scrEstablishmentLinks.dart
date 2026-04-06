import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/serEstablishment.dart';
import '../../providers/proUser.dart';
import 'dart:async';

class VinculosScreen extends StatefulWidget {
  final int estabelecimentoId;
  final List<dynamic> usuariosVinculados;

  const VinculosScreen({
    super.key,
    required this.estabelecimentoId,
    required this.usuariosVinculados,
  });

  @override
  State<VinculosScreen> createState() => _VinculosScreenState();
}

class _VinculosScreenState extends State<VinculosScreen>
    with AutomaticKeepAliveClientMixin {
  final EstabelecimentoService _service = EstabelecimentoService();
  // ignore: unused_field
  List<dynamic> _vinculados = [];
  List<dynamic> _disponiveis = [];
  List<dynamic> _vinculos = [];
  bool _isLoadingVinculados = false;
  bool _isLoadingDisponiveis = false;
  String _searchQuery = '';
  Timer? _debounce;

  bool _isMounted = true;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    // ignore: dead_null_aware_expression, dead_code
    _vinculados = widget.usuariosVinculados ?? [];
    _carregarVinculos();
    _carregarDisponiveis();
  }

  @override
  void dispose() {
    _isMounted = false;
    if (_debounce != null) {
      _debounce!.cancel();
      _debounce = null;
    }
    super.dispose();
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'ATIVO':
        return 'Ativo';
      case 'SOLICITADOEST':
        return 'Solicitado Estabelecimento';
      case 'SOLICITADOPRE':
        return 'Solicitado Prestador';
      case 'INATIVO':
        return 'Inativo';
      case 'BLOQUEADO':
        return 'Bloqueado';
      case 'RECUSADOPRE':
        return 'Recusado pelo Prestador';
      case 'RECUSADOEST':
        return 'Recusado por Você';
      default:
        return status ?? 'Desconhecido';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ATIVO':
        return Colors.green;
      case 'SOLICITADOEST':
      case 'SOLICITADOPRE':
        return Colors.orange;
      case 'INATIVO':
      case 'BLOQUEADO':
        return Colors.red;
      case 'RECUSADOPRE':
        return Colors.deepOrange;
      case 'RECUSADOEST':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _carregarDisponiveis({String? busca}) async {
    if (!_isMounted) return;

    setState(() => _isLoadingDisponiveis = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.listarPrestadoresDisponiveis(
        estabelecimentoId: widget.estabelecimentoId,
        token: token,
        busca: busca, // Passar o termo de busca
      );

      if (_isMounted) {
        if (result['success']) {
          setState(() {
            _disponiveis = result['data'] ?? [];
            _isLoadingDisponiveis = false;
          });
        } else {
          setState(() => _isLoadingDisponiveis = false);
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      setState(() => _isLoadingDisponiveis = false);
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _carregarVinculos() async {
    if (!_isMounted) return;

    setState(() => _isLoadingVinculados = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.listarVinculos(
        estabelecimentoId: widget.estabelecimentoId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          print('Dados recebidos no frontend: ${result['data']}');
          setState(() {
            _vinculos = result['data'] ?? [];
            _isLoadingVinculados = false;
          });
        } else {
          setState(() => _isLoadingVinculados = false);
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      setState(() => _isLoadingVinculados = false);
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _aceitarVinculo(int vinculoId) async {
    if (!_isMounted) return;

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.aceitarVinculo(
        vinculoId: vinculoId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          _mostrarSnackBar('Vínculo aceito com sucesso', Colors.green);
          _carregarVinculos();
          _carregarDisponiveis();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _recusarVinculo(int vinculoId) async {
    if (!_isMounted) return;
    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.recusarVinculo(
        vinculoId: vinculoId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          _mostrarSnackBar('Solicitação recusada', Colors.orange);
          _carregarVinculos();
          _carregarDisponiveis();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _desativarVinculo(int vinculoId) async {
    if (!_isMounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning, color: Colors.orange, size: 50),
        content: const Text(
          'Tem certeza que deseja desativar este vínculo?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Desativar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.desativarVinculo(
        vinculoId: vinculoId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          _mostrarSnackBar('Vínculo desativado', Colors.orange);
          _carregarVinculos();
          _carregarDisponiveis();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _reativarVinculo(int vinculoId) async {
    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      // Como não temos um método específico para reativar, podemos usar o mesmo
      // endpoint de aceitar? Ou precisamos criar um novo no backend?
      // Por enquanto, vamos usar o aceitar se o backend tratar

      // Se o backend tiver um endpoint específico:
      final result = await _service.reativarVinculo(
        vinculoId: vinculoId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          _mostrarSnackBar('Vínculo reativado com sucesso', Colors.green);
          _carregarVinculos();
          _carregarDisponiveis();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _excluirVinculo(int vinculoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning, color: Colors.red, size: 50),
        content: const Text(
          'Tem certeza que deseja excluir permanentemente este vínculo?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.excluirVinculo(
        vinculoId: vinculoId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          _mostrarSnackBar('Vínculo excluído com sucesso', Colors.orange);
          _carregarVinculos();
          _carregarDisponiveis();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _vincularUsuario(int usuarioId) async {
    if (!_isMounted) return;

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.solicitarVinculo(
        estabelecimentoId: widget.estabelecimentoId,
        usuarioId: usuarioId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          _mostrarSnackBar('Solicitação enviada com sucesso', Colors.green);
          _carregarVinculos();
          _carregarDisponiveis();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  //(removido-limpeza)
  /*
  Future<void> _desvincularUsuario(int usuarioId) async {
    if (!_isMounted) return;

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.desvincularUsuario(
        estabelecimentoId: widget.estabelecimentoId,
        usuarioId: usuarioId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          _mostrarSnackBar('Usuário desvinculado com sucesso', Colors.green);
          _carregarDisponiveis();

          // Atualizar listas
          final usuario = _vinculados.firstWhere(
            (u) => u['UsuarioId'] == usuarioId,
          );
          setState(() {
            _disponiveis.add(usuario);
            _vinculados.removeWhere((u) => u['UsuarioId'] == usuarioId);
          });
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }
  */

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

  List<dynamic> _filtrarLista(List<dynamic> lista) {
    if (_searchQuery.isEmpty) return lista;
    return lista.where((item) {
      // Para vínculos, o usuário está dentro de item['usuario']
      final usuario = item['usuario'] ?? {};
      final nome = usuario['UsuarioNome']?.toString().toLowerCase() ?? '';
      final email = usuario['UsuarioEmail']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return nome.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  // ignore: must_call_super
  Widget build(BuildContext context) {
    final vinculadosFiltrados = _filtrarLista(_vinculos);
    final disponiveisFiltrados = _filtrarLista(_disponiveis);

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
          'Gerenciar Vínculos',
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
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou telefone...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4A5C6B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _carregarDisponiveis(); // Recarregar sem busca
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4A5C6B),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (_isMounted) {
                    _carregarDisponiveis(busca: value);
                  }
                });
              },
            ),
          ),

          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Color(0xFF4A5C6B),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF4A5C6B),
                    tabs: [
                      Tab(text: 'Vinculados', icon: Icon(Icons.people)),
                      Tab(text: 'Disponíveis', icon: Icon(Icons.person_add)),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        // Aba de vinculados
                        _isLoadingVinculados
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4A5C6B),
                                ),
                              )
                            : vinculadosFiltrados.isEmpty
                            ? _buildEmptyState('Nenhum prestador vinculado')
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: vinculadosFiltrados.length,
                                itemBuilder: (context, index) {
                                  final vinculo = vinculadosFiltrados[index];
                                  final status =
                                      vinculo['UsuarioEstabelecimentoStatus'];

                                  return _buildVinculoCard(
                                    vinculo: vinculo,
                                    onAceitar: status == 'SOLICITADOPRE'
                                        ? () => _aceitarVinculo(
                                            vinculo['UsuarioEstabelecimentoId'],
                                          )
                                        : null,
                                    onRecusar: status == 'SOLICITADOPRE'
                                        ? () => _recusarVinculo(
                                            vinculo['UsuarioEstabelecimentoId'],
                                          )
                                        : null,
                                    onDesativar: status == 'ATIVO'
                                        ? () => _desativarVinculo(
                                            vinculo['UsuarioEstabelecimentoId'],
                                          )
                                        : null,
                                    onReativar: status == 'INATIVO'
                                        ? () => _reativarVinculo(
                                            vinculo['UsuarioEstabelecimentoId'],
                                          )
                                        : null,
                                    onExcluir:
                                        status == 'INATIVO' ||
                                            status == 'BLOQUEADO' || status == 'ATIVO' || status == 'SOLICITADOEST'
                                        ? () => _excluirVinculo(
                                            vinculo['UsuarioEstabelecimentoId'],
                                          )
                                        : null,
                                  );
                                },
                              ),

                        // Aba de disponíveis
                        _isLoadingDisponiveis
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF4A5C6B),
                                ),
                              )
                            : disponiveisFiltrados.isEmpty
                            ? _buildEmptyState('Nenhum prestador disponível')
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: disponiveisFiltrados.length,
                                itemBuilder: (context, index) {
                                  final usuario = disponiveisFiltrados[index];
                                  return _buildPrestadorDisponivelCard(
                                    usuario: usuario,
                                    onVincular: () =>
                                        _vincularUsuario(usuario['UsuarioId']),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Criar um card específico para prestadores disponíveis
  Widget _buildPrestadorDisponivelCard({
    required dynamic usuario,
    required VoidCallback onVincular,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4A5C6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Color(0xFF4A5C6B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario['UsuarioNome']?.toString() ?? 'Nome não informado',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usuario['UsuarioTelefone']?.toString() ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: onVincular,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Vincular'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A5C6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildVinculoCard({
    required dynamic vinculo,
    required VoidCallback? onAceitar,
    required VoidCallback? onRecusar,
    required VoidCallback? onDesativar,
    required VoidCallback? onReativar,
    required VoidCallback? onExcluir,
  }) {
    final usuario = vinculo['usuario'] ?? {};
    final status = vinculo['UsuarioEstabelecimentoStatus'] ?? 'DESCONHECIDO';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                  child: const Icon(Icons.person, color: Color(0xFF4A5C6B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario['UsuarioNome']?.toString() ??
                            'Nome não informado',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A5C6B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usuario['UsuarioTelefone']?.toString() ?? '',
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
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (onAceitar != null)
                  TextButton.icon(
                    onPressed: onAceitar,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Aceitar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                if (onRecusar != null)
                  TextButton.icon(
                    onPressed: onRecusar,
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('Recusar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                if (onDesativar != null)
                  TextButton.icon(
                    onPressed: onDesativar,
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Desativar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
                  ),
                if (onReativar != null)
                  TextButton.icon(
                    onPressed: onReativar,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reativar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                if (onExcluir != null)
                  TextButton.icon(
                    onPressed: onExcluir,
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Excluir'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
