import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modService.dart';
import '../../services/serService.dart';
import '../../providers/proUser.dart';
import 'scrPriceNew.dart';

class HistoricoPrecosScreen extends StatefulWidget {
  final int servicoId;
  final String servicoNome;

  const HistoricoPrecosScreen({
    super.key,
    required this.servicoId,
    required this.servicoNome,
  });

  @override
  State<HistoricoPrecosScreen> createState() => _HistoricoPrecosScreenState();
}

class _HistoricoPrecosScreenState extends State<HistoricoPrecosScreen> {
  List<PrecoServico> _precos = [];
  bool _isLoading = true;
  Map<String, dynamic>? _estatisticas;
  final ServicoService _servicoService = ServicoService();

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  String? _getToken() {
    final usuarioProvider = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    );
    return usuarioProvider.token;
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

  Future<void> _carregarHistorico() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = _getToken();
      if (token == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          _mostrarSnackBar('Usuário não autenticado', Colors.red);
        }
        return;
      }

      final result = await _servicoService.listarHistoricoPrecos(
        servicoId: widget.servicoId,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _precos = result['data'] ?? [];
            _estatisticas = result['estatisticas'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _mostrarSnackBar('Erro ao carregar histórico: $e', Colors.red);
      }
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
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
          'Histórico de Preços',
          style: TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
              )
            : Column(
                children: [
                  // Informações do serviço
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFF4A5C6B).withOpacity(0.1),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.build_circle,
                          size: 30,
                          color: Color(0xFF4A5C6B),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.servicoNome,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Estatísticas
                  if (_estatisticas != null) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildEstatisticaItem(
                            'Atual',
                            'R\$ ${_estatisticas!['precoAtual']?.toStringAsFixed(2) ?? '0.00'}',
                            Icons.trending_up,
                          ),
                          _buildEstatisticaItem(
                            'Médio',
                            'R\$ ${_estatisticas!['precoMedio']?.toStringAsFixed(2) ?? '0.00'}',
                            Icons.calculate,
                          ),
                          _buildEstatisticaItem(
                            'Menor',
                            'R\$ ${_estatisticas!['menorPreco']?.toStringAsFixed(2) ?? '0.00'}',
                            Icons.trending_down,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],

                  // Lista de preços
                  Expanded(
                    child: _precos.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhum histórico de preços encontrado',
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _precos.length,
                            itemBuilder: (context, index) {
                              final preco = _precos[index];
                              final isPrimeiro = index == 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isPrimeiro
                                      ? const Color(
                                          0xFF4A5C6B,
                                        ).withOpacity(0.05)
                                      : null,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isPrimeiro
                                        ? const Color(0xFF4A5C6B)
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isPrimeiro
                                          ? const Color(0xFF4A5C6B)
                                          : const Color(
                                              0xFF4A5C6B,
                                            ).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.attach_money,
                                      color: isPrimeiro
                                          ? Colors.white
                                          : const Color(0xFF4A5C6B),
                                      size: 16,
                                    ),
                                  ),
                                  title: Text(
                                    'R\$ ${preco.valor.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: isPrimeiro
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isPrimeiro
                                          ? const Color(0xFF4A5C6B)
                                          : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _formatarData(preco.dataCriacao),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  trailing: isPrimeiro
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4A5C6B),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            'Atual',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NovoPrecoScreen(
                servicoId: widget.servicoId,
                servicoNome: widget.servicoNome,
              ),
            ),
          ).then((_) => _carregarHistorico());
        },
        backgroundColor: const Color(0xFF4A5C6B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEstatisticaItem(String label, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: const Color(0xFF4A5C6B), size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF4A5C6B),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
