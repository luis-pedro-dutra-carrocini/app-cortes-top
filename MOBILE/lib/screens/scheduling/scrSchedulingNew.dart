import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modAttendant.dart';
import '../../models/modService.dart';
import '../../models/modAvailability.dart';
import '../../services/serAttendant.dart';
import '../../services/serScheduling.dart';
import '../../providers/proUser.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/conApi.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  final int? prestadorId;
  final String? prestadorNome;
  final int? estabelecimentoId;
  final String? estabelecimentoNome;
  final int? empresaId;

  const NovoAgendamentoScreen({
    super.key,
    this.prestadorId,
    this.prestadorNome,
    this.estabelecimentoId,
    this.estabelecimentoNome,
    this.empresaId,
  });

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  final PrestadorService _prestadorService = PrestadorService();
  final AgendamentoService _agendamentoService = AgendamentoService();

  // Estados da tela
  int _currentStep = 0;
  bool _isLoading = false;

  // Etapa 0: Seleção de Empresa e Estabelecimento
  bool _usandoEstabelecimento = false;
  List<dynamic> _empresas = [];
  List<dynamic> _estabelecimentos = [];
  dynamic _empresaSelecionada;
  dynamic _estabelecimentoSelecionado;
  bool _carregandoEmpresas = false;
  bool _carregandoEstabelecimentos = false;
  final TextEditingController _pesquisaEmpresaController =
      TextEditingController();

  // Etapa 1: Seleção de Prestador
  List<Prestador> _ultimosPrestadores = [];
  List<Prestador> _resultadosPesquisa = [];
  Prestador? _prestadorSelecionado;
  final TextEditingController _pesquisaController = TextEditingController();
  bool _pesquisando = false;

  // Etapa 2: Seleção de Serviços
  List<Servico> _servicosDisponiveis = [];
  List<Servico> _servicosSelecionados = [];
  bool _carregandoServicos = false;

  // Etapa 3: Seleção de Data e Hora
  DateTime _dataSelecionada = DateTime.now().add(const Duration(days: 1));
  String? _horaSelecionada;
  int? _disponibilidadeIdSelecionada;
  List<Map<String, dynamic>> _horariosDisponiveis = [];
  bool _carregandoHorarios = false;

  // Etapa 4: Observação
  final TextEditingController _observacaoController = TextEditingController();

  List<dynamic> _ultimasEmpresas = [];

  @override
  void initState() {
    super.initState();
    _carregarUltimosPrestadores();
    _carregarUltimasEmpresas();

    // Processar parâmetros de navegação
    if (widget.prestadorId != null) {
      // Criar um prestador a partir dos parâmetros
      _prestadorSelecionado = Prestador(
        id: widget.prestadorId!,
        nome: widget.prestadorNome ?? '',
        telefone: '',
        email: '',
        tipo: 'PRESTADOR',
      );
      _usandoEstabelecimento = false;
      _currentStep = 1; // Avançar para o passo de serviços
      _carregarServicosPrestador();
      _carregarHorariosDisponiveis();
    } else if (widget.estabelecimentoId != null) {
      _usandoEstabelecimento = true;
      _estabelecimentoSelecionado = {
        'id': widget.estabelecimentoId,
        'nome': widget.estabelecimentoNome,
      };
      if (widget.empresaId != null) {
        _empresaSelecionada = {'id': widget.empresaId, 'nome': ''};
      }
      _currentStep = 1; // Avançar para o passo de prestadores
      _carregarPrestadoresVinculados();
    }
  }

  // Quando mudar o estabelecimento selecionado, atualize a lista
  void _onEstabelecimentoSelecionado(dynamic estabelecimento) {
    setState(() {
      _estabelecimentoSelecionado = estabelecimento;
      _prestadorSelecionado = null;
    });

    if (_usandoEstabelecimento) {
      _carregarPrestadoresVinculados(); // Carrega prestadores do estabelecimento
    } else {
      _carregarUltimosPrestadores(); // Carrega prestadores gerais
    }

    _currentStep = 1; // Avançar para próximo passo
  }

  bool _isPhoneNumber(String text) {
    // Remove caracteres não numéricos e verifica se tem pelo menos 10 dígitos
    String digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10;
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarUltimosPrestadores() async {
    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _prestadorService.buscarUltimosPrestadores(token);

      if (mounted) {
        if (result['success']) {
          setState(() {
            _ultimosPrestadores = result['data'];
            _isLoading = false;
          });
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

  Future<void> _carregarUltimasEmpresas() async {
    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _prestadorService.buscarUltimasEmpresas(token);

      if (mounted && result['success']) {
        setState(() {
          _ultimasEmpresas = result['data'] ?? [];
        });
      }
    } catch (e) {
      print('Erro ao carregar últimas empresas: $e');
    }
  }

  Future<void> _pesquisarPrestadores() async {
    if (_pesquisaController.text.isEmpty) {
      setState(() {
        _resultadosPesquisa = [];
        _pesquisando = false;
      });
      return;
    }

    setState(() {
      _pesquisando = true;
      _isLoading = true;
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;
      if (token == null) return;

      final isPhone = _isPhoneNumber(_pesquisaController.text);
      Map<String, dynamic> result;

      if (_usandoEstabelecimento && _estabelecimentoSelecionado != null) {
        // Rota específica para prestadores por estabelecimento
        result = await _prestadorService.pesquisarPrestadoresPorEstabelecimento(
          token: token,
          estabelecimentoId: _estabelecimentoSelecionado!['id'],
          nome: isPhone ? null : _pesquisaController.text,
          telefone: isPhone ? _pesquisaController.text : null,
        );

        if (mounted && result['success']) {
          // CONVERSÃO: Os dados vêm como List<dynamic> de mapas simples
          List<Prestador> prestadores = [];
          if (result['data'] != null) {
            prestadores = (result['data'] as List)
                .map(
                  (item) => Prestador.fromJson({
                    'UsuarioId': item['id'],
                    'UsuarioNome': item['nome'],
                    'UsuarioTelefone': item['telefone'],
                    'UsuarioEmail': item['email'] ?? '',
                  }),
                )
                .toList();
          }
          setState(() {
            _resultadosPesquisa = prestadores;
            _isLoading = false;
          });
        }
      } else {
        // Rota geral de prestadores (já retorna no formato correto)
        result = await _prestadorService.pesquisarPrestadores(
          token: token,
          nome: isPhone ? null : _pesquisaController.text,
          telefone: isPhone ? _pesquisaController.text : null,
        );

        if (mounted && result['success']) {
          setState(() {
            _resultadosPesquisa = result['data'] ?? [];
            _isLoading = false;
          });
        }
      }

      // Tratamento de erro comum para ambos os casos
      if (mounted && !result['success']) {
        setState(() {
          _resultadosPesquisa = [];
          _isLoading = false;
          _pesquisando = false;
        });
        _mostrarSnackBar(result['message'], Colors.red);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _pesquisando = false;
      });
      _mostrarSnackBar('Erro na pesquisa: $e', Colors.red);
    }
  }

  Future<void> _carregarServicosPrestador() async {
    if (_prestadorSelecionado == null) return;

    setState(() {
      _carregandoServicos = true;
      _servicosSelecionados = [];
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;
      if (token == null) return;

      Map<String, dynamic> result;

      if (_usandoEstabelecimento && _estabelecimentoSelecionado != null) {
        // Serviços do prestador vinculados ao estabelecimento
        result = await _prestadorService
            .buscarServicosPrestadorPorEstabelecimento(
              prestadorId: _prestadorSelecionado!.id,
              estabelecimentoId: _estabelecimentoSelecionado!['id'],
              token: token,
            );
      } else {
        // Serviços gerais do prestador
        result = await _prestadorService.buscarServicosPrestador(
          prestadorId: _prestadorSelecionado!.id,
          token: token,
        );
      }

      if (mounted) {
        setState(() {
          _servicosDisponiveis = result['data'] ?? [];
          _carregandoServicos = false;
        });
      }
    } catch (e) {
      setState(() => _carregandoServicos = false);
      _mostrarSnackBar('Erro ao carregar serviços: $e', Colors.red);
    }
  }

  Future<void> _carregarHorariosDisponiveis() async {
    if (_prestadorSelecionado == null) return;

    setState(() {
      _carregandoHorarios = true;
      _horaSelecionada = null;
      _disponibilidadeIdSelecionada = null;
      _horariosDisponiveis = [];
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;
      if (token == null) return;

      Map<String, dynamic> result;

      if (_usandoEstabelecimento && _estabelecimentoSelecionado != null) {
        result = await _prestadorService
            .buscarDisponibilidadesPorEstabelecimento(
              prestadorId: _prestadorSelecionado!.id,
              estabelecimentoId: _estabelecimentoSelecionado!['id'],
              token: token,
              data: _dataSelecionada,
            );
      } else {
        result = await _prestadorService.buscarDisponibilidadesPrestador(
          prestadorId: _prestadorSelecionado!.id,
          token: token,
          data: _dataSelecionada,
        );
      }

      if (mounted) {
        if (result['success']) {
          final disponibilidades = result['data'] as List<Disponibilidade>;
          final horarios = disponibilidades
              .where((disp) => disp.status)
              .map((disp) => {'id': disp.id, 'hora': disp.horaInicio})
              .toList();

          setState(() {
            _horariosDisponiveis = horarios;
            _carregandoHorarios = false;
          });
        } else {
          setState(() => _carregandoHorarios = false);
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      setState(() => _carregandoHorarios = false);
      _mostrarSnackBar('Erro ao carregar horários: $e', Colors.red);
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A5C6B)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataSelecionada = picked;
      });
      _carregarHorariosDisponiveis();
    }
  }

  Future<void> _carregarEmpresas(String busca) async {
    if (busca.isEmpty) return;

    setState(() => _carregandoEmpresas = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}empresa/busca?q=$busca'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _empresas = jsonResponse['data'] ?? [];
          _carregandoEmpresas = false;
        });
      } else {
        setState(() => _carregandoEmpresas = false);
        _mostrarSnackBar('Erro ao buscar empresas', Colors.red);
      }
    } catch (e) {
      setState(() => _carregandoEmpresas = false);
      _mostrarSnackBar('Erro de conexão: $e', Colors.red);
    }
  }

  Future<void> _carregarEstabelecimentos(int empresaId) async {
    setState(() => _carregandoEstabelecimentos = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}empresa/$empresaId/estabelecimentos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _estabelecimentos = jsonResponse['data'] ?? [];
          _carregandoEstabelecimentos = false;
        });
      } else {
        setState(() => _carregandoEstabelecimentos = false);
        _mostrarSnackBar('Erro ao buscar estabelecimentos', Colors.red);
      }
    } catch (e) {
      setState(() => _carregandoEstabelecimentos = false);
      _mostrarSnackBar('Erro de conexão: $e', Colors.red);
    }
  }

  Future<void> _carregarPrestadoresVinculados() async {
    if (!_usandoEstabelecimento || _estabelecimentoSelecionado == null) return;

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;
      if (token == null) return;

      // Buscar prestadores vinculados ao estabelecimento (sem filtro de busca)
      final result = await _prestadorService
          .pesquisarPrestadoresPorEstabelecimento(
            token: token,
            estabelecimentoId: _estabelecimentoSelecionado!['id'],
            nome: null,
            telefone: null,
          );

      if (mounted) {
        if (result['success']) {
          List<Prestador> prestadores = [];
          if (result['data'] != null) {
            prestadores = (result['data'] as List)
                .map(
                  (item) => Prestador.fromJson({
                    'UsuarioId': item['id'],
                    'UsuarioNome': item['nome'],
                    'UsuarioTelefone': item['telefone'],
                    'UsuarioEmail': item['email'] ?? '',
                  }),
                )
                .toList();
          }
          setState(() {
            _ultimosPrestadores = prestadores;
            _isLoading = false;
          });
        } else {
          setState(() {
            _ultimosPrestadores = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarSnackBar('Erro ao carregar prestadores: $e', Colors.red);
    }
  }

  void _toggleServico(Servico servico) {
    setState(() {
      if (_servicosSelecionados.contains(servico)) {
        _servicosSelecionados.remove(servico);
      } else {
        _servicosSelecionados.add(servico);
      }
    });
  }

  double get _valorTotal {
    return _servicosSelecionados.fold(
      0,
      (sum, servico) => sum + (servico.precoAtual ?? 0),
    );
  }

  int get _tempoTotal {
    return _servicosSelecionados.fold(
      0,
      (sum, servico) => sum + servico.tempoMedio,
    );
  }

  Future<void> _finalizarAgendamento() async {
    if (_servicosSelecionados.isEmpty) {
      _mostrarSnackBar('Selecione pelo menos um serviço', Colors.orange);
      return;
    }

    if (_horaSelecionada == null) {
      _mostrarSnackBar('Selecione um horário', Colors.orange);
      return;
    }

    if (_disponibilidadeIdSelecionada == null) {
      // <-- NOVA VERIFICAÇÃO
      _mostrarSnackBar('Erro: disponibilidade não identificada', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final servicosIds = _servicosSelecionados.map((s) => s.id).toList();

      final result = await _agendamentoService.cadastrarAgendamento(
        token: token,
        prestadorId: _prestadorSelecionado!.id,
        disponibilidadeId: _disponibilidadeIdSelecionada!,
        dataServico: _dataSelecionada,
        horaServico: _horaSelecionada!,
        servicos: servicosIds,
        observacao: _observacaoController.text.isNotEmpty
            ? _observacaoController.text
            : null,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarDialogSucesso();
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

  void _mostrarDialogSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Agendamento Realizado!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Seu agendamento foi confirmado com sucesso',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ),
        ],
      ),
    );
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
          'Novo Agendamento',
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
            : Stepper(
                currentStep: _currentStep,
                type: StepperType.vertical,
                onStepContinue: () {
                  // PASSO 0: Tipo de busca
                  if (_currentStep == 0) {
                    if (_usandoEstabelecimento &&
                        _estabelecimentoSelecionado == null) {
                      _mostrarSnackBar(
                        'Selecione um estabelecimento ou escolha agendamento direto',
                        Colors.orange,
                      );
                      return;
                    }
                    setState(() => _currentStep++);
                    return; // <-- IMPORTANTE: adicionar return para não continuar a execução
                  }

                  // PASSO 1: Prestador
                  if (_currentStep == 1) {
                    if (_prestadorSelecionado == null) {
                      _mostrarSnackBar('Selecione um prestador', Colors.orange);
                      return;
                    }
                    setState(() => _currentStep++);
                    return;
                  }

                  // PASSO 2: Serviços
                  if (_currentStep == 2) {
                    if (_servicosSelecionados.isEmpty) {
                      _mostrarSnackBar(
                        'Selecione pelo menos um serviço',
                        Colors.orange,
                      );
                      return;
                    }
                    setState(() => _currentStep++);
                    return;
                  }

                  // PASSO 3: Horário
                  if (_currentStep == 3) {
                    if (_horaSelecionada == null) {
                      _mostrarSnackBar('Selecione um horário', Colors.orange);
                      return;
                    }
                    setState(() => _currentStep++);
                    return;
                  }

                  // PASSO 4: Finalizar
                  if (_currentStep == 4) {
                    _finalizarAgendamento();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    Navigator.pop(context);
                  }
                },
                steps: [
                  // Passo 0: Escolha do tipo de agendamento
                  Step(
                    title: const Text('Tipo de Busca'),
                    subtitle:
                        _usandoEstabelecimento &&
                            _estabelecimentoSelecionado != null
                        ? Text(
                            '${_empresaSelecionada?['nome']} - ${_estabelecimentoSelecionado!['nome']}',
                          )
                        : _usandoEstabelecimento
                        ? Text('Selecionando empresa...')
                        : Text('Agendamento direto'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.indexed,
                    content: _buildPassoInicial(),
                  ),
                  // Passo 1: Prestador (ajustado)
                  Step(
                    title: const Text('Escolha o Prestador'),
                    subtitle: _prestadorSelecionado != null
                        ? Text(_prestadorSelecionado!.nome)
                        : null,
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : StepState.indexed,
                    content: _buildPassoPrestador(),
                  ),
                  Step(
                    title: const Text('Escolha os Serviços'),
                    subtitle: _servicosSelecionados.isNotEmpty
                        ? Text(
                            '${_servicosSelecionados.length} serviço(s) selecionado(s)',
                          )
                        : null,
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2
                        ? StepState.complete
                        : StepState.indexed,
                    content: _buildPassoServicos(),
                  ),
                  Step(
                    title: const Text('Escolha Data e Horário'),
                    subtitle: _horaSelecionada != null
                        ? Text(
                            '${_dataSelecionada.day}/${_dataSelecionada.month} às $_horaSelecionada',
                          )
                        : null,
                    isActive: _currentStep >= 3,
                    state: _currentStep > 3
                        ? StepState.complete
                        : StepState.indexed,
                    content: _buildPassoHorario(),
                  ),
                  Step(
                    title: const Text('Observação (opcional)'),
                    subtitle: _observacaoController.text.isNotEmpty
                        ? Text(_observacaoController.text)
                        : null,
                    isActive: _currentStep >= 4,
                    state: _currentStep > 4
                        ? StepState.complete
                        : StepState.indexed,
                    content: _buildPassoObservacao(),
                  ),
                ],
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4A5C6B)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _currentStep == 0 ? 'Cancelar' : 'Voltar',
                              style: const TextStyle(color: Color(0xFF4A5C6B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A5C6B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _currentStep == 4 ? 'Finalizar' : 'Continuar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPassoPrestador() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de pesquisa
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: _pesquisaController,
            onChanged: (value) {
              // Força a rebuild do widget para atualizar o ícone
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Pesquisar nome ou telefone...',
              // Só mostra o botão de pesquisa se houver texto
              suffixIcon: _pesquisaController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF4A5C6B)),
                      onPressed: _pesquisarPrestadores,
                    )
                  : null, // Nada quando não há texto
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF4A5C6B),
                  width: 2,
                ),
              ),
            ),
            onFieldSubmitted: (_) => _pesquisarPrestadores(),
          ),
        ),
        // Resultados da pesquisa
        if (_pesquisando) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Resultados da pesquisa:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
          ),
          if (_resultadosPesquisa.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum prestador encontrado'),
              ),
            )
          else
            ..._resultadosPesquisa.map(
              (prestador) => _buildPrestadorTile(prestador),
            ),

          const Divider(height: 32),
        ],

        // Últimos prestadores
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Últimos prestadores:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5C6B),
            ),
          ),
        ),
        if (_ultimosPrestadores.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum prestador recente'),
            ),
          )
        else
          ..._ultimosPrestadores.map(
            (prestador) => _buildPrestadorTile(prestador),
          ),
      ],
    );
  }

  Widget _buildPrestadorTile(Prestador prestador) {
    final isSelected = _prestadorSelecionado?.id == prestador.id;

    return InkWell(
      onTap: () {
        setState(() {
          _prestadorSelecionado = prestador;
          _servicosDisponiveis = [];
          _servicosSelecionados = [];
          _horaSelecionada = null;
        });
        _carregarServicosPrestador();
        _carregarHorariosDisponiveis();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A5C6B).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A5C6B) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
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
                Icons.person,
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
                    prestador.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    prestador.telefone,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4A5C6B),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassoServicos() {
    if (_prestadorSelecionado == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Selecione um prestador primeiro'),
        ),
      );
    }

    if (_carregandoServicos) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
        ),
      );
    }

    if (_servicosDisponiveis.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Nenhum serviço disponível para este prestador'),
        ),
      );
    }

    return Column(
      children: [
        ..._servicosDisponiveis.map((servico) => _buildServicoTile(servico)),
        if (_servicosSelecionados.isNotEmpty) ...[
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${_valorTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    Text(
                      '$_tempoTotal minutos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServicoTile(Servico servico) {
    final isSelected = _servicosSelecionados.contains(servico);

    return InkWell(
      onTap: () => _toggleServico(servico),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A5C6B).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A5C6B) : Colors.grey.shade300,
          ),
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
                Icons.build,
                color: Color(0xFF4A5C6B),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    servico.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A5C6B),
                    ),
                  ),
                  if (servico.descricao != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      servico.descricao!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  servico.precoAtual != null
                      ? 'R\$ ${servico.precoAtual!.toStringAsFixed(2)}'
                      : 'R\$ 0,00',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A5C6B),
                  ),
                ),
                Text(
                  '${servico.tempoMedio} min',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFF4A5C6B) : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassoHorario() {
    if (_prestadorSelecionado == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Selecione um prestador primeiro'),
        ),
      );
    }

    return Column(
      children: [
        // Seletor de data
        InkWell(
          onTap: _selecionarData,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF4A5C6B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${_dataSelecionada.day}/${_dataSelecionada.month}/${_dataSelecionada.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A5C6B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF4A5C6B)),
              ],
            ),
          ),
        ),

        // Horários disponíveis
        if (_carregandoHorarios)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
            ),
          )
        else if (_horariosDisponiveis.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nenhum horário disponível para esta data'),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _horariosDisponiveis.map((item) {
              final hora = item['hora'] as String;
              final id = item['id'] as int;
              final isSelected = _horaSelecionada == hora;

              return FilterChip(
                label: Text(hora),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _horaSelecionada = hora;
                      _disponibilidadeIdSelecionada = id;
                    } else {
                      _horaSelecionada = null;
                      _disponibilidadeIdSelecionada = null;
                    }
                  });
                },
                selectedColor: const Color(0xFF4A5C6B).withOpacity(0.2),
                checkmarkColor: const Color(0xFF4A5C6B),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF4A5C6B)
                      : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF4A5C6B)
                        : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPassoObservacao() {
    return TextFormField(
      controller: _observacaoController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Alguma observação para o prestador?',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A5C6B), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
      ),
    );
  }

  //(removido-limpeza)
  /*
  Widget _buildPassoEmpresaEstabelecimento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escolha a Empresa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A5C6B),
          ),
        ),
        const SizedBox(height: 8),
        // Campo de busca de empresa
        TextFormField(
          controller: _pesquisaEmpresaController,
          decoration: InputDecoration(
            hintText: 'Digite nome da empresa...',
            prefixIcon: const Icon(Icons.business, color: Color(0xFF4A5C6B)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                if (_pesquisaEmpresaController.text.isNotEmpty) {
                  _carregarEmpresas(_pesquisaEmpresaController.text);
                }
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        if (_carregandoEmpresas)
          const Center(
            child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
          )
        else if (_empresas.isNotEmpty)
          ..._empresas.map((empresa) => _buildEmpresaTile(empresa)).toList(),

        if (_empresaSelecionada != null) ...[
          const Divider(height: 32),
          const Text(
            'Escolha o Estabelecimento',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5C6B),
            ),
          ),
          const SizedBox(height: 8),
          if (_carregandoEstabelecimentos)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
            )
          else if (_estabelecimentos.isNotEmpty)
            ..._estabelecimentos
                .map((est) => _buildEstabelecimentoTile(est))
                .toList(),
        ],
      ],
    );
  }
  */

  Widget _buildEmpresaTile(dynamic empresa) {
    return ListTile(
      leading: const Icon(Icons.business, color: Color(0xFF4A5C6B)),
      title: Text(empresa['nome']),
      subtitle: Text(empresa['telefone'] ?? ''),
      onTap: () {
        setState(() {
          _empresaSelecionada = empresa;
          _estabelecimentoSelecionado = null;
          _prestadorSelecionado = null;
        });
        _carregarEstabelecimentos(empresa['id']);
      },
      selected: _empresaSelecionada?['id'] == empresa['id'],
    );
  }

  Widget _buildEstabelecimentoTile(dynamic estabelecimento) {
    return ListTile(
      leading: const Icon(Icons.store, color: Color(0xFF4A5C6B)),
      title: Text(estabelecimento['nome']),
      subtitle: Text(
        '${estabelecimento['endereco']?['rua']}, N° ${estabelecimento['endereco']?['numero']} ${estabelecimento['endereco']?['bairro']}, ${estabelecimento['endereco']?['cidade']} - ${estabelecimento['endereco']?['estado']}',
      ),
      onTap: () => _onEstabelecimentoSelecionado(estabelecimento),
      selected: _estabelecimentoSelecionado?['id'] == estabelecimento['id'],
    );
  }

  Widget _buildPassoInicial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Opção 1: Agendamento direto com prestador
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ElevatedButton.icon(
            // Mudar para ElevatedButton
            onPressed: () {
              setState(() {
                _usandoEstabelecimento = false;
                _empresaSelecionada = null;
                _estabelecimentoSelecionado = null;
              });
              _carregarUltimosPrestadores(); // Recarrega prestadores gerais
            },
            icon: Icon(
              Icons.person,
              color: !_usandoEstabelecimento
                  ? Colors.white
                  : Color(0xFF4A5C6B), // Cor do ícone muda conforme seleção
            ),
            label: Text(
              'Buscar por prestador',
              style: TextStyle(
                color: !_usandoEstabelecimento
                    ? Colors.white
                    : Color(0xFF4A5C6B),
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: !_usandoEstabelecimento
                  ? const Color(0xFF4A5C6B) // Cor de fundo quando selecionado
                  : Colors.white, // Cor de fundo quando não selecionado
              foregroundColor: !_usandoEstabelecimento
                  ? Colors.white
                  : const Color(0xFF4A5C6B),
              side: BorderSide(
                color: const Color(0xFF4A5C6B),
                width: !_usandoEstabelecimento
                    ? 0
                    : 1, // Borda mais fina quando selecionado
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Separador
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('ou', style: TextStyle(color: Colors.grey)),
            ),
            Expanded(child: Divider()),
          ],
        ),

        const SizedBox(height: 16),

        // Opção 2: Agendar via empresa/estabelecimento
        ElevatedButton.icon(
          // Também ElevatedButton
          onPressed: () {
            setState(() {
              _usandoEstabelecimento = true;
            });
          },
          icon: Icon(
            Icons.business,
            color: _usandoEstabelecimento ? Colors.white : Color(0xFF4A5C6B),
          ),
          label: Text(
            'Buscar por empresa',
            style: TextStyle(
              color: _usandoEstabelecimento ? Colors.white : Color(0xFF4A5C6B),
            ),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            backgroundColor: _usandoEstabelecimento
                ? const Color(0xFF4A5C6B)
                : Colors.white,
            foregroundColor: _usandoEstabelecimento
                ? Colors.white
                : const Color(0xFF4A5C6B),
            side: BorderSide(
              color: const Color(0xFF4A5C6B),
              width: _usandoEstabelecimento ? 0 : 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Se escolheu via empresa, mostrar campos de seleção
        if (_usandoEstabelecimento) ...[
          const SizedBox(height: 16),
          const Text(
            'Escolha a Empresa',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5C6B),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pesquisaEmpresaController,
            decoration: InputDecoration(
              hintText: 'Pesquisar nome ou telefone...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () =>
                    _carregarEmpresas(_pesquisaEmpresaController.text),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_carregandoEmpresas)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
            )
          else if (_empresas.isNotEmpty)
            ..._empresas.map((empresa) => _buildEmpresaTile(empresa)).toList(),

          if (_ultimasEmpresas.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Últimas empresas:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A5C6B),
                ),
              ),
            ),
            ..._ultimasEmpresas.map((empresa) => _buildEmpresaTile(empresa)),
          ],

          if (_empresaSelecionada != null) ...[
            const Divider(height: 32),
            const Text(
              'Escolha o Estabelecimento',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5C6B),
              ),
            ),
            const SizedBox(height: 8),
            if (_carregandoEstabelecimentos)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF4A5C6B)),
              )
            else if (_estabelecimentos.isNotEmpty)
              ..._estabelecimentos
                  .map((est) => _buildEstabelecimentoTile(est))
                  .toList(),
          ],
        ],
      ],
    );
  }
}
