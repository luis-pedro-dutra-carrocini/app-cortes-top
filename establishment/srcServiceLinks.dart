import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/serEstablishment.dart';
import '../../providers/proUser.dart';

class VinculosServicoScreen extends StatefulWidget {
  final int servicoId;
  final String servicoNome;
  final int estabelecimentoId;

  const VinculosServicoScreen({
    super.key,
    required this.servicoId,
    required this.servicoNome,
    required this.estabelecimentoId,
  });

  @override
  State<VinculosServicoScreen> createState() => _VinculosServicoScreenState();
}

class _VinculosServicoScreenState extends State<VinculosServicoScreen> {
  final EstabelecimentoService _service = EstabelecimentoService();
  List<dynamic> _vinculados = [];
  List<dynamic> _disponiveis = [];
  bool _isLoadingVinculados = true;
  bool _isLoadingDisponiveis = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    await Future.wait([_carregarVinculados(), _carregarDisponiveis()]);
  }

  Future<void> _carregarVinculados() async {
    setState(() => _isLoadingVinculados = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.listarPrestadoresVinculados(
        servicoEstabelecimentoId: widget.servicoId,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _vinculados = result['data'] ?? [];
            _isLoadingVinculados = false;
          });
        } else {
          setState(() => _isLoadingVinculados = false);
        }
      }
    } catch (e) {
      setState(() => _isLoadingVinculados = false);
    }
  }

  Future<void> _carregarDisponiveis() async {
    setState(() => _isLoadingDisponiveis = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.listarPrestadoresDisponiveisParaServico(
        servicoEstabelecimentoId: widget.servicoId,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _disponiveis = result['data'] ?? [];
            _isLoadingDisponiveis = false;
          });
        } else {
          setState(() => _isLoadingDisponiveis = false);
        }
      }
    } catch (e) {
      setState(() => _isLoadingDisponiveis = false);
    }
  }

  Future<void> _vincularPrestador(int prestadorId) async {
    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      // Dialog para valor inicial
      double? valorInicial;
      await showDialog(
        context: context,
        builder: (context) => _ValorInicialDialog(
          onConfirm: (valor) {
            valorInicial = valor;
            Navigator.pop(context);
          },
        ),
      );

      if (valorInicial == null) return;

      if (valorInicial == 0) return;

      final result = await _service.vincularServicoAPrestador(
        servicoEstabelecimentoId: widget.servicoId,
        prestadorId: prestadorId,
        valorInicial: valorInicial,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar('Prestador vinculado com sucesso', Colors.green);
          _carregarDados();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _desvincularPrestador(int servicoVinculadoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning, color: Colors.orange, size: 50),
        content: const Text(
          'Tem certeza que deseja desvincular este prestador desse serviço?',
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
            child: const Text('Desvincular'),
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

      final result = await _service.desvincularServicoDePrestador(
        servicoId: servicoVinculadoId,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar('Prestador desvinculado', Colors.orange);
          _carregarDados();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
    }
  }

  Future<void> _mostrarDialogPrecoUnificado() async {
    final precoController = TextEditingController();

    final valor = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Preço Unico'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Este preço será aplicado a TODOS os prestadores vinculados a este serviço.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: precoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), // Retorna null
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valorDigitado = double.tryParse(
                precoController.text.replaceAll(',', '.'),
              );
              if (valorDigitado != null && valorDigitado > 0) {
                Navigator.pop(context, valorDigitado); // Retorna o valor double
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informe um valor válido'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5C6B),
            ),
            child: const Text('Aplicar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (valor != null && valor > 0) {
      _atualizarPrecoUnificado(valor);
    }
  }

  Future<void> _atualizarPrecoUnificado(double valor) async {
    setState(() => _isLoadingDisponiveis = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.atualizarPrecoUnificadoServico(
        servicoEstabelecimentoId: widget.servicoId,
        valor: valor,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar(
            'Preço atualizado para todos os prestadores!',
            Colors.green,
          );
          _carregarVinculados();
          _carregarDisponiveis();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
          setState(() => _isLoadingDisponiveis = false);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
      setState(() => _isLoadingDisponiveis = false);
    }
  }

  Future<void> _mostrarDialogAlterarPrecoIndividual(
    int vinculoId,
    double? precoAtual,
  ) async {
    final precoController = TextEditingController(
      text: precoAtual != null ? precoAtual.toStringAsFixed(2) : '',
    );

    final valor = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Preço Individual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Altere o preço para este prestador específico',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: precoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final valorDigitado = double.tryParse(
                precoController.text.replaceAll(',', '.'),
              );
              if (valorDigitado != null && valorDigitado > 0) {
                Navigator.pop(context, valorDigitado);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Informe um valor válido'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5C6B),
            ),
            child: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (valor != null && valor > 0) {
      _atualizarPrecoIndividual(vinculoId, valor);
    }
  }

  Future<void> _atualizarPrecoIndividual(int vinculoId, double valor) async {
    setState(() => _isLoadingVinculados = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      // Usar o mesmo método de adicionar preço, mas passando o vinculoId como servicoId
      final result = await _service.adicionarPrecoServico(
        servicoId: vinculoId,
        valor: valor,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar('Preço atualizado com sucesso', Colors.green);
          _carregarVinculados();
        } else {
          _mostrarSnackBar(result['message'], Colors.red);
          setState(() => _isLoadingVinculados = false);
        }
      }
    } catch (e) {
      _mostrarSnackBar('Erro: $e', Colors.red);
      setState(() => _isLoadingVinculados = false);
    }
  }

  void _mostrarSnackBar(String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          'Vínculos - ${widget.servicoNome}',
          style: const TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money, color: Color(0xFF4A5C6B)),
            onPressed: () => _mostrarDialogPrecoUnificado(),
          ),
        ],
      ),
      body: DefaultTabController(
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
                  // Vinculados
                  _isLoadingVinculados
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A5C6B),
                          ),
                        )
                      : _vinculados.isEmpty
                      ? _buildEmptyState('Nenhum prestador vinculado')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _vinculados.length,
                          itemBuilder: (context, index) {
                            final item = _vinculados[index];
                            return _buildVinculadoCard(item);
                          },
                        ),
                  // Disponíveis
                  _isLoadingDisponiveis
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A5C6B),
                          ),
                        )
                      : _disponiveis.isEmpty
                      ? _buildEmptyState('Nenhum prestador disponível')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _disponiveis.length,
                          itemBuilder: (context, index) {
                            final prestador = _disponiveis[index];
                            return _buildDisponivelCard(prestador);
                          },
                        ),
                ],
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

  Widget _buildVinculadoCard(dynamic item) {
    final prestador = item['prestador'] ?? {};
    final precoAtual = item['precoAtual'];
    final vinculoId = item['vinculoId'];

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
                    prestador['UsuarioNome'] ?? 'Nome não informado',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (precoAtual != null)
                    InkWell(
                      onTap: () => _mostrarDialogAlterarPrecoIndividual(
                        vinculoId,
                        precoAtual?.toDouble(),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'R\$ ${precoAtual.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: () =>
                          _mostrarDialogAlterarPrecoIndividual(vinculoId, null),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Definir preço'),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF4A5C6B),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _desvincularPrestador(item['vinculoId']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisponivelCard(dynamic prestador) {
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
                    prestador['UsuarioNome'] ?? 'Nome não informado',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF4A5C6B)),
              onPressed: () => _vincularPrestador(prestador['UsuarioId']),
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog para valor inicial
class _ValorInicialDialog extends StatefulWidget {
  final Function(double) onConfirm;

  const _ValorInicialDialog({required this.onConfirm});

  @override
  State<_ValorInicialDialog> createState() => __ValorInicialDialogState();
}

class __ValorInicialDialogState extends State<_ValorInicialDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Valor do Serviço', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Informe o valor inicial para este serviço com esse prestador',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'R\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
            final valor = double.tryParse(
              _controller.text.replaceAll(',', '.'),
            );
            if (valor != null && valor > 0) {
              widget.onConfirm(valor);
            } else {
              widget.onConfirm(0);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4A5C6B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
