import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/modScheduling.dart';
import '../../models/modService.dart';
import '../../services/serScheduling.dart';
import '../../services/serAttendant.dart';
import '../../providers/proUser.dart';
import '../../models/modAvailability.dart';

class EditarAgendamentoScreen extends StatefulWidget {
  final Agendamento agendamento;

  const EditarAgendamentoScreen({super.key, required this.agendamento});

  @override
  State<EditarAgendamentoScreen> createState() => _SchedulingEditScreenState();
}

class _SchedulingEditScreenState extends State<EditarAgendamentoScreen> {
  late Agendamento _agendamento;

  // Controladores
  DateTime _dataSelecionada = DateTime.now();
  String? _horaSelecionada;
  int? _disponibilidadeIdSelecionada;
  List<int> _servicosSelecionados = [];
  final TextEditingController _observacaoController = TextEditingController();

  // Estados
  bool _isLoading = false;
  bool _carregandoServicos = false;
  bool _carregandoHorarios = false;

  // Dados
  List<Servico> _servicosDisponiveis = [];
  List<Map<String, dynamic>> _horariosDisponiveis = [];

  final AgendamentoService _agendamentoService = AgendamentoService();
  final PrestadorService _prestadorService = PrestadorService();

  @override
  void initState() {
    super.initState();
    _agendamento = widget.agendamento;
    _dataSelecionada = _agendamento.dataServico;
    _horaSelecionada = _agendamento.horaServico;
    _observacaoController.text = _agendamento.observacao ?? '';
    _disponibilidadeIdSelecionada = _agendamento.disponibilidadeId;

    // Extrair IDs dos serviços selecionados
    if (_agendamento.servicos != null) {
      _servicosSelecionados = _agendamento.servicos!
          .map<int>((item) {
            // Acessar corretamente a estrutura do JSON
            if (item is Map<String, dynamic>) {
              if (item['servico'] is Map<String, dynamic>) {
                return (item['servico']['ServicoId'] ?? 0) as int;
              } else if (item['ServicoId'] != null) {
                return (item['ServicoId'] ?? 0) as int;
              }
            }
            return 0;
          })
          .where((id) => id != 0)
          .toList();
    }

    _carregarServicos();
    _carregarHorariosDisponiveis();
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarServicos() async {
    setState(() => _carregandoServicos = true);

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      var result = await _prestadorService.buscarServicosPrestador(
        prestadorId: _agendamento.prestadorId,
        token: token,
      );

      if (_agendamento.estabelecimento?['EstabelecimentoId'] != null) {
        result = await _prestadorService
            .buscarServicosPrestadorPorEstabelecimento(
              estabelecimentoId:
                  _agendamento.estabelecimento?['EstabelecimentoId'],
              prestadorId: _agendamento.prestadorId,
              token: token,
            );
      }

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
    setState(() {
      _carregandoHorarios = true;
      _horariosDisponiveis = [];
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(
        context,
        listen: false,
      );
      final token = usuarioProvider.token;

      if (token == null) return;

      print('Buscando disponibilidades para data: $_dataSelecionada');

      final result = await _prestadorService.buscarDisponibilidadesPrestador(
        prestadorId: _agendamento.prestadorId,
        token: token,
        data: _dataSelecionada,
      );

      if (mounted) {
        if (result['success']) {
          final List<Disponibilidade> disponibilidades = result['data'] ?? [];

          print('Disponibilidades recebidas: ${disponibilidades.length}');

          // Extrair horários disponíveis com ID (status true)
          List<Map<String, dynamic>> horarios = [];
          for (var disp in disponibilidades) {
            if (disp.horaInicio.isNotEmpty) {
              // Incluir TODOS os horários, independente do status
              horarios.add({
                'id': disp.id,
                'hora': disp.horaInicio,
                'status': disp.status,
                'isCurrent': false,
              });
            }
          }

          print('Horários da API: $horarios');

          // VARIÁVEIS PARA CONTROLE
          bool isDataOriginal = _dataSelecionada == _agendamento.dataServico;
          bool horarioOriginalEstaNaLista = horarios.any(
            (h) => h['hora'] == _agendamento.horaServico,
          );

          // SOLUÇÃO: Forçar a inclusão do horário original se for a data original
          if (isDataOriginal && !horarioOriginalEstaNaLista) {
            print(
              'Forçando inclusão do horário original: ${_agendamento.horaServico}',
            );
            horarios.add({
              'id': _agendamento.disponibilidadeId,
              'hora': _agendamento.horaServico,
              'status': false, // Importante: marcar como indisponível
              'isCurrent': true,
            });

            // Ordenar novamente
            horarios.sort((a, b) => a['hora'].compareTo(b['hora']));
          }

          // DEFINIR O HORÁRIO SELECIONADO
          String? horarioParaSelecionar;
          int? idParaSelecionar;

          if (isDataOriginal) {
            // CASO 1: É a data original - FORÇAR seleção do horário original
            horarioParaSelecionar = _agendamento.horaServico;

            // Encontrar o ID correspondente (pode ser o original ou outro)
            var horarioOriginal = horarios.firstWhere(
              (h) => h['hora'] == _agendamento.horaServico,
              orElse: () => {},
            );

            if (horarioOriginal.isNotEmpty) {
              idParaSelecionar = horarioOriginal['id'] as int?;
            }

            print('Data original - Forçando seleção: $horarioParaSelecionar');
          } else {
            // CASO 2: Data diferente - tentar manter seleção anterior se ainda disponível
            if (_horaSelecionada != null) {
              bool horarioAindaDisponivel = horarios.any(
                (h) => h['hora'] == _horaSelecionada && h['status'] == true,
              );

              if (horarioAindaDisponivel) {
                horarioParaSelecionar = _horaSelecionada;
                var horarioEncontrado = horarios.firstWhere(
                  (h) => h['hora'] == _horaSelecionada,
                );
                idParaSelecionar = horarioEncontrado['id'] as int?;

                print('Mantendo seleção anterior: $horarioParaSelecionar');
              } else {
                print('Horário anterior não disponível, limpando seleção');
              }
            }
          }

          setState(() {
            _horariosDisponiveis = horarios;

            // Aplicar a seleção definida
            if (horarioParaSelecionar != null) {
              _horaSelecionada = horarioParaSelecionar;
              _disponibilidadeIdSelecionada = idParaSelecionar;
            } else {
              _horaSelecionada = null;
              _disponibilidadeIdSelecionada = null;
            }

            _carregandoHorarios = false;
          });

          print('Horários finais: $_horariosDisponiveis');
          print('Horário selecionado: $_horaSelecionada');
          print('ID selecionado: $_disponibilidadeIdSelecionada');
        } else {
          setState(() {
            _carregandoHorarios = false;
          });
          _mostrarSnackBar(result['message'], Colors.red);
        }
      }
    } catch (e) {
      print('Erro ao carregar horários: $e');
      if (mounted) {
        setState(() {
          _carregandoHorarios = false;
        });
        _mostrarSnackBar('Erro ao carregar horários', Colors.red);
      }
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
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

    if (picked != null && picked != _dataSelecionada) {
      // Guardar o horário atual antes de mudar
      String? horarioAnterior = _horaSelecionada;

      setState(() {
        _dataSelecionada = picked;
      });

      await _carregarHorariosDisponiveis();

      // Se após carregar não houver horário selecionado, tentar reselecionar o anterior
      if (_horaSelecionada == null && horarioAnterior != null) {
        bool horarioAnteriorExiste = _horariosDisponiveis.any(
          (h) => h['hora'] == horarioAnterior,
        );

        if (horarioAnteriorExiste) {
          setState(() {
            _horaSelecionada = horarioAnterior;
            var horarioEncontrado = _horariosDisponiveis.firstWhere(
              (h) => h['hora'] == horarioAnterior,
            );
            _disponibilidadeIdSelecionada = horarioEncontrado['id'] as int?;
          });
        }
      }
    }
  }

  void _toggleServico(Servico servico) {
    setState(() {
      if (_servicosSelecionados.contains(servico.id)) {
        _servicosSelecionados.remove(servico.id);
      } else {
        _servicosSelecionados.add(servico.id);
      }
    });
  }

  double get _valorTotal {
    double total = 0;
    for (var servico in _servicosDisponiveis) {
      if (_servicosSelecionados.contains(servico.id)) {
        total += servico.precoAtual ?? 0;
      }
    }
    return total;
  }

  int get _tempoTotal {
    int total = 0;
    for (var servico in _servicosDisponiveis) {
      if (_servicosSelecionados.contains(servico.id)) {
        total += servico.tempoMedio;
      }
    }
    return total;
  }

  Future<void> _salvarAlteracoes() async {
    if (_servicosSelecionados.isEmpty) {
      _mostrarSnackBar('Selecione pelo menos um serviço', Colors.orange);
      return;
    }

    if (_horaSelecionada == null) {
      _mostrarSnackBar('Selecione um horário', Colors.orange);
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

      // Verificar se houve alterações
      final dataAlterada = _dataSelecionada != _agendamento.dataServico;
      final horaAlterada = _horaSelecionada != _agendamento.horaServico;
      final observacaoAlterada =
          _observacaoController.text != (_agendamento.observacao ?? '');

      List<int> servicosAntigos = _agendamento.servicos!
          .map<int>((item) {
            // Tenta extrair o ID de diferentes formas
            if (item is Map<String, dynamic>) {
              // Verifica se tem a estrutura com 'servico'
              if (item.containsKey('servico') &&
                  item['servico'] is Map<String, dynamic>) {
                return (item['servico']['ServicoId'] ?? 0) as int;
              }
              // Verifica se tem ServicoId diretamente
              else if (item.containsKey('ServicoId')) {
                return (item['ServicoId'] ?? 0) as int;
              }
              // Verifica se tem 'servico' como mapa
              else if (item['servico'] != null) {
                var servico = item['servico'];
                if (servico is Map<String, dynamic> &&
                    servico.containsKey('ServicoId')) {
                  return (servico['ServicoId'] ?? 0) as int;
                }
              }
            }
            return 0;
          })
          .where((id) => id != 0) // Remove IDs inválidos
          .toList();

      final servicosAlterados = !_listasIguais(
        servicosAntigos,
        _servicosSelecionados,
      );

      if (!dataAlterada &&
          !horaAlterada &&
          !observacaoAlterada &&
          !servicosAlterados) {
        _mostrarSnackBar('Nenhuma alteração detectada', Colors.orange);
        setState(() => _isLoading = false);
        return;
      }

      final result = await _agendamentoService.atualizarAgendamento(
        agendamentoId: _agendamento.id,
        token: token,
        disponibilidadeId: _disponibilidadeIdSelecionada, // NOVO
        dataServico: dataAlterada ? _dataSelecionada : null,
        horaServico: horaAlterada ? _horaSelecionada : null,
        observacao: observacaoAlterada ? _observacaoController.text : null,
        servicos: servicosAlterados ? _servicosSelecionados : null,
      );

      if (mounted) {
        if (result['success']) {
          _mostrarSnackBar('Agendamento atualizado com sucesso!', Colors.green);
          Navigator.pop(context, true);
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

  bool _listasIguais(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    return a.every((item) => b.contains(item));
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
          'Editar Agendamento',
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informação do prestador (não editável)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
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
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prestador',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  _agendamento.prestador?['UsuarioNome'] ??
                                      'Prestador',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A5C6B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Data
                    const Text(
                      'Data do serviço',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selecionarData,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF4A5C6B),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_dataSelecionada.day}/${_dataSelecionada.month}/${_dataSelecionada.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF4A5C6B),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Horário
                    const Text(
                      'Horário',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_carregandoHorarios)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A5C6B),
                          ),
                        ),
                      )
                    else if (_horariosDisponiveis.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Nenhum horário disponível para esta data',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _horariosDisponiveis.map((item) {
                          final hora = item['hora'] as String;
                          final status = item['status'] ?? true;
                          final isCurrent = item['isCurrent'] == true;
                          final isSelected = _horaSelecionada == hora;

                          // CORREÇÃO: Tratar ID nulo
                          final int? id = item['id'] as int?;

                          // Determinar cores baseado no status
                          Color backgroundColor = Colors.transparent;
                          Color textColor = Colors.grey.shade700;
                          Color borderColor = Colors.grey.shade300;

                          if (isSelected) {
                            backgroundColor = const Color(
                              0xFF4A5C6B,
                            ).withOpacity(0.2);
                            textColor = const Color(0xFF4A5C6B);
                            borderColor = const Color(0xFF4A5C6B);
                          } else if (isCurrent) {
                            backgroundColor = Colors.blue.shade50;
                            textColor = Colors.blue.shade800;
                            borderColor = Colors.blue.shade400;
                          } else if (!status) {
                            // Horários indisponíveis (não originais) - mais transparentes
                            backgroundColor = Colors.grey.shade100;
                            textColor = Colors.grey.shade500;
                            borderColor = Colors.grey.shade300;
                          }

                          return FilterChip(
                            label: Text(hora),
                            selected: isSelected,
                            onSelected: status || isCurrent
                                ? (selected) {
                                    // Só permite selecionar se status true ou é o atual
                                    setState(() {
                                      if (selected) {
                                        _horaSelecionada = hora;
                                        _disponibilidadeIdSelecionada = id;
                                      } else {
                                        _horaSelecionada = null;
                                        _disponibilidadeIdSelecionada = null;
                                      }
                                    });
                                  }
                                : null, // Desabilitado se não disponível e não é o atual
                            selectedColor: const Color(
                              0xFF4A5C6B,
                            ).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF4A5C6B),
                            backgroundColor: backgroundColor,
                            labelStyle: TextStyle(
                              color: textColor,
                              fontWeight: isCurrent || isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              decoration: !status && !isCurrent
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: borderColor),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 20),

                    // Serviços
                    const Text(
                      'Serviços',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_carregandoServicos)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4A5C6B),
                        ),
                      )
                    else if (_servicosDisponiveis.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('Nenhum serviço disponível'),
                        ),
                      )
                    else
                      ..._servicosDisponiveis.map(
                        (servico) => _buildServicoTile(servico),
                      ),

                    if (_servicosSelecionados.isNotEmpty) ...[
                      const SizedBox(height: 16),
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

                    const SizedBox(height: 20),

                    // Observação
                    const Text(
                      'Observação',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4A5C6B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
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
                          borderSide: const BorderSide(
                            color: Color(0xFF4A5C6B),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF4A5C6B)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Color(0xFF4A5C6B)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _salvarAlteracoes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A5C6B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Salvar'),
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

  Widget _buildServicoTile(Servico servico) {
    final isSelected = _servicosSelecionados.contains(servico.id);

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
}
