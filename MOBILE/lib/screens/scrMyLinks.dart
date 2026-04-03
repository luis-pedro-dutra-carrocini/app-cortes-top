import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/serEstablishment.dart';
import '../../providers/proUser.dart';
import 'dart:async';

class MeusVinculosScreen extends StatefulWidget {
  const MeusVinculosScreen({super.key});

  @override
  State<MeusVinculosScreen> createState() => _MeusVinculosScreenState();
}

class _MeusVinculosScreenState extends State<MeusVinculosScreen>
    with AutomaticKeepAliveClientMixin {
  final EstabelecimentoService _service = EstabelecimentoService();
  List<dynamic> _vinculos = [];
  bool _isLoading = true;
  //(removido-limpeza)String _searchQuery = '';
  Timer? _debounce;

  bool _isMounted = true;

  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();
    _carregarVinculos();
  }

  @override
  void dispose() {
    _isMounted = false;
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _carregarVinculos() async {
    if (!_isMounted) return;

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      // Usar o método correto para buscar vínculos do prestador
      final result = await _service.listarVinculosPrestador(token: token);

      if (_isMounted) {
        if (result['success']) {
          setState(() {
            _vinculos = result['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      if (_isMounted) {
        setState(() => _isLoading = false);
        _mostrarSnackBar('Erro: $e', Colors.red);
      }
    }
  }

  Future<void> _aceitarVinculo(int vinculoId) async {
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
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _recusarVinculo(int vinculoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning, color: Colors.orange, size: 50),
        content: const Text(
          'Tem certeza que deseja recusar esta solicitação?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Recusar'),
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

      final result = await _service.recusarVinculo(
        vinculoId: vinculoId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          _mostrarSnackBar('Solicitação recusada', Colors.orange);
          _carregarVinculos();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _desativarVinculo(int vinculoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning, color: Colors.orange, size: 50),
        content: const Text(
          'Tem certeza que deseja excluir este vínculo?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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

      final result = await _service.desativarVinculo(
        vinculoId: vinculoId,
        token: token,
      );

      if (_isMounted) {
        if (result['success']) {
          _mostrarSnackBar('Vínculo desativado', Colors.orange);
          _carregarVinculos();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
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

  String _getStatusText(String? status) {
    switch (status) {
      case 'ATIVO':
        return 'Ativo';
      case 'SOLICITADOEST':
        return 'Solicitação do Estabelecimento';
      case 'SOLICITADOPRE':
        return 'Solicitação Enviada';
      case 'INATIVO':
        return 'Inativado pelo Estabelecimento';
      case 'BLOQUEADO':
        return 'Bloqueado';
      case 'RECUSADOPRE':
        return 'Recusado por Você';
      case 'RECUSADOEST':
        return 'Recusado pelo Estabelecimento';
      default:
        return status ?? 'Desconhecido';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ATIVO':
        return Colors.green;
      case 'SOLICITADOEST':
        return Colors.blue;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
          'Meus Vínculos',
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
          : _vinculos.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vinculos.length,
              itemBuilder: (context, index) {
                final vinculo = _vinculos[index];
                return _buildVinculoCard(vinculo);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhum vínculo encontrado',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Quando um estabelecimento solicitar vínculo,\nele aparecerá aqui',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildVinculoCard(dynamic vinculo) {
    final estabelecimento = vinculo['estabelecimento'] ?? {};
    final status = vinculo['UsuarioEstabelecimentoStatus'] ?? 'DESCONHECIDO';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estabelecimento['EstabelecimentoNome'] ??
                            'Nome não informado',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF4A5C6B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Empresa: ${estabelecimento['empresa']?['EmpresaNome'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
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
                const SizedBox(width: 20),
                const Icon(Icons.phone, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  estabelecimento['EstabelecimentoTelefone'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'SOLICITADOEST')
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => _aceitarVinculo(
                          vinculo['UsuarioEstabelecimentoId'],
                        ),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Aceitar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _recusarVinculo(
                          vinculo['UsuarioEstabelecimentoId'],
                        ),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Recusar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                if (status == 'ATIVO')
                  TextButton.icon(
                    onPressed: () =>
                        _desativarVinculo(vinculo['UsuarioEstabelecimentoId']),
                    icon: const Icon(Icons.block, size: 18),
                    label: const Text('Excluir'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                if (status == 'RECUSADOPRE')
                  TextButton.icon(
                    onPressed: () =>
                        _aceitarVinculo(vinculo['UsuarioEstabelecimentoId']),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Cancelar Recusa e Aceitar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
