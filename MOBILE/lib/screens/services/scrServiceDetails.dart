import 'package:flutter/material.dart';
import '../../models/modService.dart';
import '../../services/serService.dart';
import 'scrServiceEdit.dart';
import 'scrPriceHistory.dart';
import 'scrPriceNew.dart';
import 'package:provider/provider.dart';
import '../../providers/proUser.dart';

class DetalhesServicoScreen extends StatefulWidget {
  final Servico servico;

  const DetalhesServicoScreen({super.key, required this.servico});

  @override
  State<DetalhesServicoScreen> createState() => _DetalhesServicoScreenState();
}

class _DetalhesServicoScreenState extends State<DetalhesServicoScreen> {
  late Servico _servico;
  bool _isLoading = false;
  final ServicoService _servicoService = ServicoService();

  @override
  void initState() {
    super.initState();
    _servico = widget.servico;
  }

  String? _getToken() {
    final usuarioProvider = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    );
    return usuarioProvider.token;
  }

  Future<void> _recarregarServico() async {
    final token = _getToken();
    if (token == null) return;

    final result = await _servicoService.buscarServico(_servico.id, token);
    if (result['success'] && mounted) {
      setState(() {
        _servico = result['data'];
      });
    }
  }

  Future<void> _alternarStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = _getToken();
      if (token == null) {
        _mostrarSnackBar('Usuário não autenticado', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final result = await _servicoService.alternarStatusServico(
        servicoId: _servico.id,
        token: token,
        ativo: !_servico.ativo,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _servico = result['data'];
            _isLoading = false;
          });

          _mostrarSnackBar(
            _servico.ativo ? 'Serviço ativado' : 'Serviço desativado',
            Colors.green,
          );
        } else {
          setState(() => _isLoading = false);
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarSnackBar('Erro: $e', Colors.red);
      }
    }
  }

  void _mostrarDialogExcluir() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 50,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Excluir Serviço',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 15),
            Text(
              'Tem certeza que deseja excluir este serviço?',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
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
              _excluirServico();
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

  Future<void> _excluirServico() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = _getToken();
      if (token == null) {
        _mostrarSnackBar('Usuário não autenticado', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final result = await _servicoService.excluirServico(_servico.id, token);

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar('Serviço excluído com sucesso', Colors.green);
          Navigator.pop(context, true); // Voltar e indicar que excluiu
        } else {
          setState(() => _isLoading = false);
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarSnackBar('Erro ao excluir: $e', Colors.red);
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
          'Detalhes do Serviço',
          style: TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF4A5C6B)),
            onSelected: (value) {
              if (value == 'editar') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditarServicoScreen(servico: _servico),
                  ),
                ).then((atualizado) {
                  if (atualizado != null && atualizado) {
                    _recarregarServico(); // Recarregar dados ao voltar
                  }
                });
              } else if (value == 'historico') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoricoPrecosScreen(
                      servicoId: _servico.id,
                      servicoNome: _servico.nome,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'editar',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'historico',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18),
                    SizedBox(width: 8),
                    Text('Histórico de Preços'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de status
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Status:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _servico.ativo
                                    ? Colors.green.shade600
                                    : Colors.grey.shade600,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _servico.ativo ? 'ATIVO' : 'INATIVO',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Preço atual:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _servico.precoAtual != null
                                  ? 'R\$ ${_servico.precoAtual!.toStringAsFixed(2)}'
                                  : 'Não definido',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tempo médio:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_servico.tempoMedio} minutos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Informações detalhadas
                  _buildInfoSection(
                    title: 'Informações do Serviço',
                    children: [
                      _buildInfoRow('Nome:', _servico.nome),
                      if (_servico.descricao != null &&
                          _servico.descricao!.isNotEmpty)
                        _buildInfoRow(
                          'Descrição:',
                          _servico.descricao!,
                          isMultiline: true,
                        ),
                      _buildInfoRow('ID do Serviço:', '#${_servico.id}'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Ações rápidas
                  _buildInfoSection(
                    title: 'Ações Rápidas',
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A5C6B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Color(0xFF4A5C6B),
                            size: 20,
                          ),
                        ),
                        title: const Text('Adicionar Novo Preço'),
                        subtitle: const Text('Registrar alteração de preço'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NovoPrecoScreen(
                                servicoId: _servico.id,
                                servicoNome: _servico.nome,
                              ),
                            ),
                          ).then((_) {
                            _recarregarServico(); // Recarregar dados ao voltar
                          });
                        },
                      ),
                      const Divider(),
                      SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A5C6B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _servico.ativo ? Icons.toggle_on : Icons.toggle_off,
                            color: const Color(0xFF4A5C6B),
                            size: 20,
                          ),
                        ),
                        title: const Text('Ativar/Desativar Serviço'),
                        subtitle: Text(
                          _servico.ativo
                              ? 'Serviço visível para clientes'
                              : 'Serviço oculto para clientes',
                        ),
                        value: _servico.ativo,
                        activeColor: const Color(0xFF4A5C6B),
                        onChanged: (bool valor) {
                          _alternarStatus(); // Chama a função sem usar o valor
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Excluir Serviço',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text(
                          'Remover permanentemente',
                          style: TextStyle(color: Colors.red),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.red,
                        ),
                        onTap: _mostrarDialogExcluir,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF4A5C6B)),
          ),
        ],
      ),
    );
  }
}
