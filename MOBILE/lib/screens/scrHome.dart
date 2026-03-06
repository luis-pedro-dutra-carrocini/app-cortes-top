import 'package:flutter/material.dart';
import '../models/modUser.dart';
import '../services/serAuth.dart';
import 'scrUserProfile.dart';
import 'package:provider/provider.dart';
import '../providers/proUser.dart';
import 'services/scrServiceList.dart';
import '../services/serDashboard.dart';
import '../services/serScheduling.dart';
import 'availability/scrAvailabilityList.dart';
import 'scheduling/scrSchedulingNew.dart';
import 'scheduling/scrSchedulingDetail.dart';
import 'schedulingAttendant/scrSchedulingList.dart';
import 'establishment/scrEstablishmentList.dart';

class HomeScreen extends StatefulWidget {
  final Usuario usuario;
  final String token;

  const HomeScreen({super.key, required this.usuario, required this.token});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Usuario _usuario;
  late String _token;
  final AuthService _authService = AuthService();

  final DashboardService _dashboardService = DashboardService();
  Map<String, dynamic>? _resumoRapido;
  bool _carregandoResumo = true;
  bool _usuarioBloqueado = false;

  // Ícones para as opções
  final Map<String, IconData> _icons = {
    'Gerenciar Disponibilidade': Icons.event_available,
    'Gerenciar Agendamentos': Icons.calendar_month,
    'Gerenciar Serviços': Icons.build_circle,
    'Gerenciar Conta': Icons.person,
    'Iniciar novo Agendamento': Icons.add_circle,
    'Meu Agendamento': Icons.event,
    'Gerenciar Estabelecimentos': Icons.storefront,
  };

  final AgendamentoService _agendamentoService =
      AgendamentoService(); // Você precisará criar este serviço
  List<dynamic> _agendamentosPendentes = [];
  bool _carregandoAgendamentos = false;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _token = widget.token;

    // Verificar se o usuário está bloqueado (UsuarioAtivo = false)
    _usuarioBloqueado = !_usuario.ativo;

    _salvarDadosLogin();

    if (_usuario.tipo == 'PRESTADOR') {
      _carregarResumoRapido();
    } else if (_usuario.tipo == 'CLIENTE') {
      _carregarAgendamentosPendentes();
    }
  }

  Future<void> _carregarResumoRapido() async {
    if (_usuario.tipo != 'PRESTADOR') return;

    setState(() {
      _carregandoResumo = true;
    });

    try {
      final result = await _dashboardService.obterResumoRapido(_token);
      if (mounted && result['success']) {
        setState(() {
          _resumoRapido = result['data'];
          _carregandoResumo = false;
        });
      } else {
        setState(() {
          _carregandoResumo = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar resumo: $e');
      setState(() {
        _carregandoResumo = false;
      });
    }
  }

  Future<void> _salvarDadosLogin() async {
    await _authService.saveUserData(_token, _usuario);
  }

  Future<void> _carregarAgendamentosPendentes() async {
    if (_usuario.tipo != 'CLIENTE') return;

    setState(() {
      _carregandoAgendamentos = true;
    });

    try {
      final result = await _agendamentoService.listarMeusAgendamentosPendentes(
        _token,
      );
      if (mounted && result['success']) {
        setState(() {
          _agendamentosPendentes = result['data'];
          _carregandoAgendamentos = false;
        });
      } else {
        setState(() {
          _carregandoAgendamentos = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar agendamentos: $e');
      setState(() {
        _carregandoAgendamentos = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();

    // Limpar o provider
    final usuarioProvider = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    );
    usuarioProvider.logout();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /*
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
  */

  void _navegarPara(String opcao) {
    if (opcao == 'Gerenciar Conta') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PerfilScreen(usuario: _usuario, token: _token),
        ),
      );
    } else if (opcao == 'Gerenciar Serviços') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ListaServicosScreen()),
      );
    } else if (opcao == 'Gerenciar Disponibilidade') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ListaDisponibilidadeScreen(),
        ),
      );
    } else if (opcao == 'Iniciar novo Agendamento') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NovoAgendamentoScreen()),
      );
    } else if (opcao == 'Gerenciar Agendamentos') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ListaAgendamentosPrestadorScreen(),
        ),
      );
    } else if (opcao == 'Gerenciar Estabelecimentos') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ListaEstabelecimentosScreen(),
        ),
      );
    } else {
      // TODO: Implementar outras navegações
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navegando para: $opcao'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getOpcoesPrestador() {
    // Se estiver bloqueado, mostra apenas Gerenciar Conta
    if (_usuarioBloqueado) {
      return [
        {'titulo': 'Gerenciar Conta', 'icone': _icons['Gerenciar Conta']},
      ];
    }

    return [
      {
        'titulo': 'Gerenciar Disponibilidade',
        'icone': _icons['Gerenciar Disponibilidade'],
      },
      {
        'titulo': 'Gerenciar Agendamentos',
        'icone': _icons['Gerenciar Agendamentos'],
      },
      {'titulo': 'Gerenciar Serviços', 'icone': _icons['Gerenciar Serviços']},
      {'titulo': 'Gerenciar Conta', 'icone': _icons['Gerenciar Conta']},
    ];
  }

  List<Map<String, dynamic>> _getOpcoesCliente() {
    // Se estiver bloqueado, mostra apenas Gerenciar Conta
    if (_usuarioBloqueado) {
      return [
        {'titulo': 'Gerenciar Conta', 'icone': _icons['Gerenciar Conta']},
      ];
    }

    List<Map<String, dynamic>> opcoes = [];

    opcoes.addAll([
      {
        'titulo': 'Iniciar novo Agendamento',
        'icone': _icons['Iniciar novo Agendamento'],
      },
      {'titulo': 'Gerenciar Conta', 'icone': _icons['Gerenciar Conta']},
    ]);

    return opcoes;
  }

  List<Map<String, dynamic>> _getOpcoesEmpresa() {
    // Se estiver bloqueado, mostra apenas Gerenciar Conta
    if (_usuarioBloqueado) {
      return [
        {'titulo': 'Gerenciar Conta', 'icone': _icons['Gerenciar Conta']},
      ];
    }

    List<Map<String, dynamic>> opcoes = [];

    opcoes.addAll([
      {'titulo': 'Gerenciar Estabelecimentos', 'icone': _icons['Gerenciar Estabelecimentos']},
      {'titulo': 'Gerenciar Conta', 'icone': _icons['Gerenciar Conta']},
    ]);

    return opcoes;
  }

  String _getSaudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) {
      return 'Bom dia';
    } else if (hora < 18) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrestador = _usuario.tipo == 'PRESTADOR';
    final bool isEmpresa = _usuario.tipo == 'EMPRESA';
    //final bool isCliente = _usuario.tipo == 'CLIENTE';
    final opcoes = isPrestador
        ? _getOpcoesPrestador()
        : (isEmpresa ? _getOpcoesEmpresa() : _getOpcoesCliente());

    // Use Consumer em vez de Provider.of para ter mais controle
    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, child) {
        // Verificação segura - se não houver usuário, redireciona para login
        if (usuarioProvider.usuario == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const SizedBox.shrink(); // Retorna widget vazio enquanto redireciona
        }

        final usuario = usuarioProvider.usuario!; // Agora é seguro usar "!"

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Início',
              style: TextStyle(
                color: const Color(0xFF4A5C6B),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: const Color(0xFF4A5C6B),
                ),
                onPressed: () {
                  // TODO: Abrir notificações
                },
              ),
              IconButton(
                icon: Icon(Icons.logout, color: const Color(0xFF4A5C6B)),
                onPressed: () {
                  _logout();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com saudação e informações do usuário
                  Container(
                    width: double.infinity,
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
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A5C6B).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Icon(
                                isPrestador ? Icons.build : Icons.person,
                                size: 35,
                                color: const Color(0xFF4A5C6B),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getSaudacao()},',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    usuario.nome,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isPrestador
                                          ? 'Prestador de Serviços'
                                          : 'Cliente',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // BANNER DE AVISO PARA USUÁRIOS BLOQUEADOS
                  if (_usuarioBloqueado) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade800,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Atenção!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Os recursos de sua conta estão temporariamente bloqueados devido a pendências financeiras. '
                                  'Regularize sua situação e volte a usar todos os recursos do app.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 25),

                  // Título da seção
                  Text(
                    isPrestador ? 'Menu do Prestador' : 'Menu do Cliente',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Grid de opções
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    itemCount: opcoes.length,
                    itemBuilder: (context, index) {
                      final opcao = opcoes[index];
                      return _buildMenuCard(
                        titulo: opcao['titulo'],
                        icone: opcao['icone'],
                        onTap: () => _navegarPara(opcao['titulo']),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Ações rápidas (opcional)
                  if (!_usuarioBloqueado) ...[
                    if (isPrestador) ...[
                      const Divider(height: 30),
                      const Text(
                        'Resumo do Dia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A5C6B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildResumoCard(),
                    ] else if (_usuario.tipo == 'CLIENTE') ...[
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Meus Agendamentos Pendentes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4A5C6B),
                            ),
                          ),
                          TextButton(
                            onPressed: _carregarAgendamentosPendentes,
                            child: const Text(
                              'Atualizar',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4A5C6B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildAgendamentosPendentesCard(),
                    ],
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
        );
      },
    );
  }

  Widget _buildMenuCard({
    required String titulo,
    required IconData? icone,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A5C6B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 30, color: const Color(0xFF4A5C6B)),
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendamentosPendentesCard() {
    if (_carregandoAgendamentos) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
        ),
      );
    }

    if (_agendamentosPendentes.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_busy, size: 40, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'Nenhum agendamento pendente',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            SizedBox(height: 5),
            Text(
              'Que tal agendar um serviço?',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Mostrar apenas os 3 primeiros agendamentos
          ..._agendamentosPendentes.take(3).map((agendamento) {
            return _buildAgendamentoTile(agendamento);
          }),

          if (_agendamentosPendentes.length > 3) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  'e mais ${_agendamentosPendentes.length - 3} agendamento(s)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgendamentoTile(dynamic agendamento) {
    final data = DateTime.parse(agendamento['AgendamentoDtServico']);
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SchedulingDetailScreen(
              agendamentoId: agendamento['AgendamentoId'],
            ),
          ),
        ).then((_) {
          // Recarregar lista ao voltar se algo foi alterado
          _carregarAgendamentosPendentes();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
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
              child: const Icon(
                Icons.event,
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
                    agendamento['prestador']['UsuarioNome'] ?? 'Prestador',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dataFormatada,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        agendamento['AgendamentoHoraServico'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${agendamento['servicos']?.length ?? 0} serviço(s)',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                agendamento['AgendamentoStatus'] ?? 'PENDENTE',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoCard() {
    if (_carregandoResumo) {
      return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResumoItem(
                'Agendamentos',
                _resumoRapido != null
                    ? '${_resumoRapido!['agendamentosHoje'] ?? 0}'
                    : '0',
                Icons.calendar_today,
              ),
              _buildResumoItem(
                'Disponível',
                _resumoRapido != null
                    ? '${_resumoRapido!['horasDisponiveisHoje']?.toStringAsFixed(1) ?? '0'}h'
                    : '0h',
                Icons.access_time,
              ),
              _buildResumoItem(
                'Faturamento',
                _resumoRapido != null
                    ? 'R\$ ${_resumoRapido!['faturamentoMes']?.toStringAsFixed(2) ?? '0'}'
                    : 'R\$ 0',
                Icons.attach_money,
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Botão "Ver mais detalhes"
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navegar para tela de Dashboard completa
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Dashboard completo em breve!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart, size: 18),
            label: const Text('Ver mais detalhes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4A5C6B),
              side: const BorderSide(color: Color(0xFF4A5C6B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoItem(String label, String valor, IconData icone) {
    return Column(
      children: [
        Icon(icone, color: const Color(0xFF4A5C6B), size: 20),
        const SizedBox(height: 5),
        Text(
          valor,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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

  Widget _buildBottomBar() {
    // Obter o tipo de usuário do Provider
    final usuarioProvider = Provider.of<UsuarioProvider>(
      context,
      listen: false,
    );
    final isPrestador = usuarioProvider.usuario?.tipo == 'PRESTADOR';
    final isEmpresa = usuarioProvider.usuario?.tipo == 'EMPRESA';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Início - sempre visível
              _buildNavItem(Icons.home, 'Início', true),

              // Buscar - visível apenas para não prestadores
              if (!isPrestador && !isEmpresa)
                _buildNavItem(Icons.search, 'Buscar', false),

              // Novo - visível para todos
              if (!isPrestador && !isEmpresa)
                _buildNavItem(Icons.add_circle, 'Novo', false, isFAB: true),

              // Histórico - visível apenas para não prestadores
              if (!isPrestador && !isEmpresa)
                _buildNavItem(Icons.history, 'Histórico', false),

              // Perfil - sempre visível
              _buildNavItem(
                Icons.person,
                'Perfil',
                false,
                onTap: () {
                  _navegarPara('Gerenciar Conta');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icone,
    String label,
    bool isSelected, {
    bool isFAB = false,
    VoidCallback? onTap,
  }) {
    if (isFAB) {
      return GestureDetector(
        onTap: onTap ?? () => _navegarPara('Iniciar novo Agendamento'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4A5C6B),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4A5C6B).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icone, color: Colors.white, size: 30),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icone,
            color: isSelected ? const Color(0xFF4A5C6B) : Colors.grey,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFF4A5C6B) : Colors.grey,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
