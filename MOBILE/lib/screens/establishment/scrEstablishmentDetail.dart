import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modEstablishment.dart';
import '../../services/serEstablishment.dart';
import '../../providers/proUser.dart';
import 'scrEstablishmentForm.dart';
import 'scrEstablishmentLinks.dart';
import 'scrServicesEstablishment.dart';

class EstabelecimentoDetailScreen extends StatefulWidget {
  final int estabelecimentoId;

  const EstabelecimentoDetailScreen({
    super.key,
    required this.estabelecimentoId,
  });

  @override
  State<EstabelecimentoDetailScreen> createState() =>
      _EstabelecimentoDetailScreenState();
}

class _EstabelecimentoDetailScreenState
    extends State<EstabelecimentoDetailScreen> {
  final EstabelecimentoService _service = EstabelecimentoService();
  Estabelecimento? _estabelecimento;
  List<dynamic> _usuarios = [];
  // ignore: unused_field
  List<dynamic> _servicos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.buscarEstabelecimento(
        estabelecimentoId: widget.estabelecimentoId,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _estabelecimento = result['data'];
            _usuarios = result['usuarios'] ?? [];
            _servicos = result['servicos'] ?? [];
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

  Future<void> _alternarStatus(bool ativo) async {
    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _service.alternarStatus(
        estabelecimentoId: widget.estabelecimentoId,
        token: token,
        ativo: ativo,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar(result['message'], Colors.green);
          _carregarDados();
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'ATIVO':
        return Colors.green;
      case 'INATIVO':
        return Colors.red;
      default:
        return Colors.orange;
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
          'Detalhes do Estabelecimento',
          style: TextStyle(
            color: Color(0xFF4A5C6B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        // No AppBar, no ícone de editar:
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF4A5C6B)),
            onPressed: () {
              if (_estabelecimento != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstabelecimentoFormScreen(
                      estabelecimento: _estabelecimento!
                          .toMap(), // USAR toMap()
                    ),
                  ),
                ).then((_) => _carregarDados());
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
            )
          : _estabelecimento == null
          ? const Center(child: Text('Estabelecimento não encontrado'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de informações principais
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
                                color: _getStatusColor(
                                  _estabelecimento!.status,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                _estabelecimento!.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(Icons.store, color: Colors.white70),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _estabelecimento!.nome,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Informações de contato
                  _buildInfoSection(
                    title: 'Contato',
                    icon: Icons.phone,
                    children: [
                      _buildInfoRow('Telefone', _estabelecimento!.telefone),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Endereço
                  _buildInfoSection(
                    title: 'Endereço',
                    icon: Icons.location_on,
                    children: [
                      _buildInfoRow('CEP', _estabelecimento!.cep ?? ''),
                      _buildInfoRow(
                        'Logradouro',
                        '${_estabelecimento!.rua ?? ""}, ${_estabelecimento!.numero ?? ""}',
                      ),
                      if (_estabelecimento!.complemento != null)
                        _buildInfoRow(
                          'Complemento',
                          _estabelecimento!.complemento!,
                        ),
                      _buildInfoRow('Bairro', _estabelecimento!.bairro ?? ''),
                      _buildInfoRow(
                        'Cidade/UF',
                        '${_estabelecimento!.cidade ?? ""}/${_estabelecimento!.estado ?? ""}',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Prestadores vinculados
                  _buildVinculosSection(),

                  const SizedBox(height: 20),

                  // Botões de ação
                  Column(
                    children: [
                      // Botão Gerenciar Vínculos
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VinculosScreen(
                                estabelecimentoId: widget.estabelecimentoId,
                                usuariosVinculados: _usuarios,
                              ),
                            ),
                          ).then((_) => _carregarDados());
                        },
                        icon: const Icon(
                          Icons.people,
                          color: Color(0xFF4A5C6B),
                        ),
                        label: const Text(
                          'Gerenciar Vínculos',
                          style: TextStyle(color: Color(0xFF4A5C6B)),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: Color(0xFF4A5C6B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Botão Gerenciar Serviços
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ServicosEstabelecimentoScreen(
                                    estabelecimentoId: widget.estabelecimentoId,
                                    estabelecimentoNome: _estabelecimento!.nome,
                                  ),
                            ),
                          ).then((_) => _carregarDados());
                        },
                        icon: const Icon(Icons.build, color: Color(0xFF4A5C6B)),
                        label: const Text(
                          'Gerenciar Serviços',
                          style: TextStyle(color: Color(0xFF4A5C6B)),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: Color(0xFF4A5C6B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Botão de status
                      if (_estabelecimento!.status == 'ATIVO')
                        OutlinedButton.icon(
                          onPressed: () => _alternarStatus(false),
                          icon: const Icon(Icons.block, color: Colors.red),
                          label: const Text(
                            'Desativar Estabelecimento',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: () => _alternarStatus(true),
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          label: const Text(
                            'Ativar Estabelecimento',
                            style: TextStyle(color: Colors.green),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
    required IconData icon,
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
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF4A5C6B), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5C6B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A5C6B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVinculosSection() {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: Color(0xFF4A5C6B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Prestadores (${_usuarios.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VinculosScreen(
                          estabelecimentoId: widget.estabelecimentoId,
                          usuariosVinculados: _usuarios,
                        ),
                      ),
                    ).then((_) => _carregarDados());
                  },
                  icon: const Icon(Icons.account_tree, size: 16),
                  label: const Text('Gerenciar'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4A5C6B),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_usuarios.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Nenhum prestador vinculado',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ..._usuarios.take(3).map((usuario) => _buildUsuarioTile(usuario)),
          if (_usuarios.length > 3)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'e mais ${_usuarios.length - 3} prestador(es)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUsuarioTile(dynamic usuario) {
    // Status do vínculo (prioridade sobre status do usuário)
    final vinculoStatus = usuario['vinculoStatus'] ?? 'DESCONHECIDO';

    Color getStatusColor() {
      switch (vinculoStatus) {
        case 'ATIVO':
          return Colors.green;
        case 'SOLICITADOEST':
        case 'SOLICITADOPRE':
          return Colors.orange;
        case 'INATIVO':
        case 'BLOQUEADO':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    String getStatusText() {
      switch (vinculoStatus) {
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
        default:
          return vinculoStatus;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A5C6B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF4A5C6B), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario['UsuarioNome'] ?? 'Nome não informado',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  usuario['UsuarioTelefone'] ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              getStatusText(),
              style: TextStyle(
                fontSize: 10,
                color: getStatusColor(),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
