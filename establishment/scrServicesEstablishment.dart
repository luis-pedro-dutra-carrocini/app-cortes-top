import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/serEstablishment.dart';
import '../../providers/proUser.dart';
import 'scrServiceEstablishmentForm.dart';
import 'srcServiceLinks.dart';

class ServicosEstabelecimentoScreen extends StatefulWidget {
  final int estabelecimentoId;
  final String estabelecimentoNome;

  const ServicosEstabelecimentoScreen({
    super.key,
    required this.estabelecimentoId,
    required this.estabelecimentoNome,
  });

  @override
  State<ServicosEstabelecimentoScreen> createState() =>
      _ServicosEstabelecimentoScreenState();
}

class _ServicosEstabelecimentoScreenState
    extends State<ServicosEstabelecimentoScreen> {
  final EstabelecimentoService _service = EstabelecimentoService();
  List<dynamic> _servicos = [];
  bool _isLoading = true;
  //(removido-limpeza)bool _showInativos = false;

  @override
  void initState() {
    super.initState();
    _carregarServicos();
  }

  Future<void> _carregarServicos() async {
    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.listarTodosServicosEstabelecimento(
        estabelecimentoId: widget.estabelecimentoId,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _servicos = result['data'] ?? [];
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

  Future<void> _confirmarInativacao(dynamic servico) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.warning, color: Colors.orange, size: 50),
        content: Text(
          'Deseja realmente inativar o serviço "${servico['ServicoNome']}"?\n\n'
          'Isso não afetará vínculos existentes, mas o serviço não poderá ser vinculado a novos prestadores. E os clientes não poderão solicita-lo',
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
            child: const Text('Inativar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _alternarStatusServico(servico['ServicoEstabelecimentoId'], false);
    }
  }

  Future<void> _confirmarAtivacao(dynamic servico) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: Text(
          'Deseja realmente ativar o serviço "${servico['ServicoNome']}"?',
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ativar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _alternarStatusServico(servico['ServicoEstabelecimentoId'], true);
    }
  }

  Future<void> _alternarStatusServico(int servicoId, bool ativo) async {
    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      // Buscar o serviço atual para obter os dados completos
      final servicoAtual = _servicos.firstWhere(
        (s) => s['ServicoEstabelecimentoId'] == servicoId,
      );

      final result = await _service.atualizarServicoEstabelecimento(
        servicoId: servicoId,
        nome: servicoAtual['ServicoNome'],
        descricao: servicoAtual['ServicoDescricao'],
        tempoMedio: servicoAtual['ServicoTempoMedio'],
        ativo: ativo,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar(
            ativo
                ? 'Serviço ativado com sucesso'
                : 'Serviço inativado com sucesso',
            ativo ? Colors.green : Colors.orange,
          );
          _carregarServicos();
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
          'Serviços Prestados',
          style: const TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
                  builder: (context) => ServicoEstabelecimentoFormScreen(
                    estabelecimentoId: widget.estabelecimentoId,
                  ),
                ),
              ).then((_) => _carregarServicos());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Lista de serviços
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
                  )
                : _servicos.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _servicos.length,
                    itemBuilder: (context, index) {
                      final servico = _servicos[index];
                      return _buildServicoCard(servico);
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
          Icon(Icons.build_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Nenhum serviço cadastrado',
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

  Widget _buildServicoCard(dynamic servico) {
    final isAtivo = servico['ServicoAtivo'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navegar para tela de vínculos
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VinculosServicoScreen(
                servicoId: servico['ServicoEstabelecimentoId'],
                servicoNome: servico['ServicoNome'],
                estabelecimentoId: widget.estabelecimentoId,
              ),
            ),
          ).then((_) => _carregarServicos());
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
                      Icons.build,
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
                          servico['ServicoNome'] ?? 'Sem nome',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                        if (servico['ServicoDescricao'] != null)
                          Text(
                            servico['ServicoDescricao'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF4A5C6B)),
                    onSelected: (value) async {
                      if (value == 'editar') {
                        // Abrir tela de edição
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ServicoEstabelecimentoFormScreen(
                                  estabelecimentoId: widget.estabelecimentoId,
                                  servico: servico,
                                ),
                          ),
                        );
                        if (result == true) {
                          _carregarServicos();
                        }
                      } else if (value == 'inativar' && isAtivo) {
                        _confirmarInativacao(servico);
                      } else if (value == 'ativar' && !isAtivo) {
                        _confirmarAtivacao(servico);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: Color(0xFF4A5C6B),
                            ),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      if (isAtivo)
                        const PopupMenuItem(
                          value: 'inativar',
                          child: Row(
                            children: [
                              Icon(Icons.block, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Inativar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem(
                          value: 'ativar',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ativar',
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${servico['ServicoTempoMedio'] ?? 0} minutos',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.people, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${servico['_count']?['servicos'] ?? 0} prestador(es)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isAtivo ? Colors.green : Colors.red).withOpacity(
                        0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAtivo ? 'Ativo' : 'Inativo',
                      style: TextStyle(
                        fontSize: 11,
                        color: isAtivo ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      servico['faixaPreco'] ?? 'Preço não definido',
                      style: TextStyle(
                        fontSize: 12,
                        color: servico['precoMin'] != null
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                        fontWeight: servico['precoMin'] != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
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
}
