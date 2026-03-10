import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modAttendant.dart';
import '../../models/modService.dart';
import '../../models/modAvailability.dart';
import '../../services/serAttendant.dart';
import '../../services/serScheduling.dart';
import '../../providers/proUser.dart';

class NovoAgendamentoScreen extends StatefulWidget {
  const NovoAgendamentoScreen({super.key});

  @override
  State<NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends State<NovoAgendamentoScreen> {
  final PrestadorService _prestadorService = PrestadorService();
  final AgendamentoService _agendamentoService = AgendamentoService();

  // Estados da tela
  int _currentStep = 0;
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _carregarUltimosPrestadores();
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
      _resultadosPesquisa = []; // <-- LIMPAR resultados anteriores
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      final result = await _prestadorService.pesquisarPrestadores(
        token: token,
        nome: _isPhoneNumber(_pesquisaController.text)
            ? null
            : _pesquisaController.text,
        telefone: _isPhoneNumber(_pesquisaController.text)
            ? _pesquisaController.text
            : null,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _resultadosPesquisa = result['data'];
            _isLoading = false;
            // _pesquisando continua true enquanto mostra resultados
          });
        } else {
          setState(() {
            _isLoading = false;
            _pesquisando =
                false; // <-- Importante: desativar modo pesquisa em caso de erro
          });
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _pesquisando = false; // <-- Desativar modo pesquisa em caso de erro
        });
        _mostrarSnackBar('Erro: $e', Colors.red);
      }
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

      final result = await _prestadorService.buscarServicosPrestador(
        prestadorId: _prestadorSelecionado!.id,
        token: token,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _servicosDisponiveis = result['data'];
            _carregandoServicos = false;
          });
        } else {
          setState(() => _carregandoServicos = false);
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregandoServicos = false);
        _mostrarSnackBar('Erro: $e', Colors.red);
      }
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

      final result = await _prestadorService.buscarDisponibilidadesPrestador(
        prestadorId: _prestadorSelecionado!.id,
        token: token,
        data: _dataSelecionada,
      );

      if (mounted) {
        if (result['success']) {
          final disponibilidades = result['data'] as List<Disponibilidade>;

          // Extrair horários disponíveis com ID
          final horarios = disponibilidades
              .where((disp) => disp.status)
              .map((disp) => {'id': disp.id, 'hora': disp.horaInicio})
              .toList();

          setState(() {
            _horariosDisponiveis = horarios;
            _carregandoHorarios = false;
          });
        } else {
          setState(() {
            _carregandoHorarios = false;
          });
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _carregandoHorarios = false;
        });
        _mostrarSnackBar('Erro ao carregar horários: $e', Colors.red);
      }
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
                  if (_currentStep == 0 && _prestadorSelecionado == null) {
                    _mostrarSnackBar('Selecione um prestador', Colors.orange);
                    return;
                  }
                  if (_currentStep == 1 && _servicosSelecionados.isEmpty) {
                    _mostrarSnackBar(
                      'Selecione pelo menos um serviço',
                      Colors.orange,
                    );
                    return;
                  }
                  if (_currentStep == 2 && _horaSelecionada == null) {
                    _mostrarSnackBar('Selecione um horário', Colors.orange);
                    return;
                  }
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
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
                  Step(
                    title: const Text('Escolha o Prestador'),
                    subtitle: _prestadorSelecionado != null
                        ? Text(_prestadorSelecionado!.nome)
                        : null,
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
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
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : (_currentStep == 1
                              ? StepState.editing
                              : StepState.indexed),
                    content: _buildPassoServicos(),
                  ),
                  Step(
                    title: const Text('Escolha Data e Horário'),
                    subtitle: _horaSelecionada != null
                        ? Text(
                            '${_dataSelecionada.day}/${_dataSelecionada.month} às $_horaSelecionada',
                          )
                        : null,
                    isActive: _currentStep >= 2,
                    state: _currentStep > 2
                        ? StepState.complete
                        : (_currentStep == 2
                              ? StepState.editing
                              : StepState.indexed),
                    content: _buildPassoHorario(),
                  ),
                  Step(
                    title: const Text('Observação (opcional)'),
                    subtitle: _observacaoController.text.isNotEmpty
                        ? Text(_observacaoController.text)
                        : null,
                    isActive: _currentStep >= 3,
                    state: _currentStep > 3
                        ? StepState.complete
                        : (_currentStep == 3
                              ? StepState.editing
                              : StepState.indexed),
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
                              _currentStep == 3 ? 'Finalizar' : 'Continuar',
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
            decoration: InputDecoration(
              hintText: 'Pesquisar nome ou telefone...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF4A5C6B)),
              suffixIcon: _pesquisaController.text.isNotEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botão de busca (aparece quando há texto)
                        IconButton(
                          icon: const Icon(
                            Icons.search,
                            size: 18,
                            color: Color(0xFF4A5C6B),
                          ),
                          onPressed: _pesquisarPrestadores,
                        ),
                        // Botão de limpar
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _pesquisaController.clear();
                            setState(() {
                              _resultadosPesquisa = [];
                              _pesquisando = false;
                            });
                          },
                        ),
                      ],
                    )
                  : null,
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
}
