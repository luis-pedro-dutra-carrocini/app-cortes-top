// src/controllers/agendamentoController.js
const prisma = require('../prisma.js');

class AgendamentoController {

    // Cadastrar agendamento (apenas CLIENTE)
    async cadastrarAgendamento(req, res) {
        try {
            const {
                PrestadorId,
                AgendamentoDtServico,
                AgendamentoHoraServico,
                servicos // Array de IDs dos serviços
            } = req.body;

            // Verificar se o usuário é CLIENTE
            if (req.usuario.usuarioTipo !== 'CLIENTE') {
                return res.status(403).json({ 
                    error: 'Apenas clientes podem realizar agendamentos' 
                });
            }

            // Validações básicas
            if (!PrestadorId) {
                return res.status(400).json({ error: 'ID do prestador é obrigatório' });
            }

            if (!AgendamentoDtServico) {
                return res.status(400).json({ error: 'Data do serviço é obrigatória' });
            }

            if (!AgendamentoHoraServico || !AgendamentoHoraServico.trim()) {
                return res.status(400).json({ error: 'Hora do serviço é obrigatória' });
            }

            if (!servicos || !Array.isArray(servicos) || servicos.length === 0) {
                return res.status(400).json({ error: 'Pelo menos um serviço deve ser selecionado' });
            }

            // Validar formato da hora (HH:MM)
            const horaRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
            if (!horaRegex.test(AgendamentoHoraServico)) {
                return res.status(400).json({ error: 'Hora do serviço deve estar no formato HH:MM (ex: 14:30)' });
            }

            // Validar se a data é futura
            const dataServico = new Date(AgendamentoDtServico);
            const hoje = new Date();
            hoje.setHours(0, 0, 0, 0);
            
            if (dataServico < hoje) {
                return res.status(400).json({ error: 'A data do serviço deve ser futura' });
            }

            // Verificar se o prestador existe e é PRESTADOR
            const prestador = await prisma.usuario.findUnique({
                where: { UsuarioId: parseInt(PrestadorId) }
            });

            if (!prestador) {
                return res.status(404).json({ error: 'Prestador não encontrado' });
            }

            if (prestador.UsuarioTipo !== 'PRESTADOR') {
                return res.status(400).json({ error: 'O usuário informado não é um prestador' });
            }

            // Verificar se os serviços existem e pertencem ao prestador
            const servicosEncontrados = await prisma.servico.findMany({
                where: {
                    ServicoId: { in: servicos.map(id => parseInt(id)) },
                    PrestadorId: parseInt(PrestadorId),
                    ServicoAtivo: true
                },
                include: {
                    precos: {
                        orderBy: {
                            ServicoPrecoDtCriacao: 'desc'
                        },
                        take: 1
                    }
                }
            });

            if (servicosEncontrados.length !== servicos.length) {
                return res.status(400).json({ 
                    error: 'Um ou mais serviços são inválidos ou não pertencem ao prestador' 
                });
            }

            // Verificar disponibilidade do prestador
            const diaSemana = dataServico.getDay(); // 0-6 (domingo-sábado)
            
            const disponibilidade = await prisma.disponibilidade.findFirst({
                where: {
                    PrestadorId: parseInt(PrestadorId),
                    DisponibilidadeDiaSemana: diaSemana,
                    DisponibilidadeHoraInicio: { lte: AgendamentoHoraServico },
                    DisponibilidadeHoraFim: { gt: AgendamentoHoraServico }
                }
            });

            if (!disponibilidade) {
                return res.status(400).json({ 
                    error: 'Prestador não disponível neste dia e horário' 
                });
            }

            // Verificar conflito de horário com outros agendamentos
            const conflito = await prisma.agendamento.findFirst({
                where: {
                    PrestadorId: parseInt(PrestadorId),
                    AgendamentoDtServico: dataServico,
                    AgendamentoHoraServico: AgendamentoHoraServico,
                    AgendamentoStatus: { notIn: ['CANCELADO', 'CONCLUIDO'] }
                }
            });

            if (conflito) {
                return res.status(409).json({ 
                    error: 'Já existe um agendamento para este horário' 
                });
            }

            // Calcular totais
            let valorTotal = 0;
            let tempoTotal = 0;

            servicosEncontrados.forEach(servico => {
                if (servico.precos && servico.precos.length > 0) {
                    valorTotal += parseFloat(servico.precos[0].ServicoValor);
                }
                tempoTotal += servico.ServicoTempoMedio;
            });

            // Criar agendamento em transação
            const resultado = await prisma.$transaction(async (prisma) => {
                // Criar agendamento
                const agendamento = await prisma.agendamento.create({
                    data: {
                        PrestadorId: parseInt(PrestadorId),
                        ClienteId: req.usuario.usuarioId,
                        AgendamentoDtServico: dataServico,
                        AgendamentoHoraServico: AgendamentoHoraServico,
                        AgendamentoValorTotal: valorTotal,
                        AgendamentoTempoGasto: tempoTotal,
                        AgendamentoStatus: 'PENDENTE'
                    }
                });

                // Criar relações com serviços
                const servicosAgendamento = await Promise.all(
                    servicosEncontrados.map(servico => 
                        prisma.servicoAgendamento.create({
                            data: {
                                AgendamentoId: agendamento.AgendamentoId,
                                ServicoId: servico.ServicoId
                            }
                        })
                    )
                );

                // Buscar agendamento completo com relações
                const agendamentoCompleto = await prisma.agendamento.findUnique({
                    where: { AgendamentoId: agendamento.AgendamentoId },
                    include: {
                        prestador: {
                            select: {
                                UsuarioId: true,
                                UsuarioNome: true,
                                UsuarioEmail: true,
                                UsuarioTelefone: true
                            }
                        },
                        cliente: {
                            select: {
                                UsuarioId: true,
                                UsuarioNome: true,
                                UsuarioEmail: true,
                                UsuarioTelefone: true
                            }
                        },
                        servicos: {
                            include: {
                                servico: {
                                    include: {
                                        precos: {
                                            orderBy: {
                                                ServicoPrecoDtCriacao: 'desc'
                                            },
                                            take: 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                });

                return agendamentoCompleto;
            });

            // Formatar resposta
            const respostaFormatada = {
                ...resultado,
                AgendamentoValorTotal: parseFloat(resultado.AgendamentoValorTotal),
                servicos: resultado.servicos.map(sa => ({
                    ServicoAgendamentoId: sa.ServicoAgendamentoId,
                    servico: {
                        ...sa.servico,
                        precoAtual: sa.servico.precos && sa.servico.precos.length > 0 
                            ? parseFloat(sa.servico.precos[0].ServicoValor) 
                            : null
                    }
                }))
            };

            res.status(201).json({
                message: 'Agendamento realizado com sucesso',
                data: respostaFormatada
            });

        } catch (error) {
            console.error('Erro ao cadastrar agendamento:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Listar agendamentos do cliente logado
    async listarMeusAgendamentosCliente(req, res) {
        try {
            const agendamentos = await prisma.agendamento.findMany({
                where: {
                    ClienteId: req.usuario.usuarioId
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    },
                    servicos: {
                        include: {
                            servico: {
                                select: {
                                    ServicoId: true,
                                    ServicoNome: true,
                                    ServicoDescricao: true,
                                    ServicoTempoMedio: true
                                }
                            }
                        }
                    }
                },
                orderBy: [
                    {
                        AgendamentoDtServico: 'desc'
                    },
                    {
                        AgendamentoHoraServico: 'desc'
                    }
                ]
            });

            // Formatar resposta
            const agendamentosFormatados = agendamentos.map(ag => ({
                ...ag,
                AgendamentoValorTotal: parseFloat(ag.AgendamentoValorTotal),
                servicos: ag.servicos.map(s => s.servico)
            }));

            res.status(200).json({ 
                data: agendamentosFormatados,
                total: agendamentos.length
            });

        } catch (error) {
            console.error('Erro ao listar agendamentos:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Listar agendamentos do prestador logado (apenas PRESTADOR)
    async listarMeusAgendamentosPrestador(req, res) {
        try {
            // Verificar se é prestador
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({ 
                    error: 'Apenas prestadores podem acessar esta rota' 
                });
            }

            const agendamentos = await prisma.agendamento.findMany({
                where: {
                    PrestadorId: req.usuario.usuarioId
                },
                include: {
                    cliente: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    },
                    servicos: {
                        include: {
                            servico: {
                                select: {
                                    ServicoId: true,
                                    ServicoNome: true,
                                    ServicoDescricao: true,
                                    ServicoTempoMedio: true
                                }
                            }
                        }
                    }
                },
                orderBy: [
                    {
                        AgendamentoDtServico: 'desc'
                    },
                    {
                        AgendamentoHoraServico: 'desc'
                    }
                ]
            });

            // Formatar resposta
            const agendamentosFormatados = agendamentos.map(ag => ({
                ...ag,
                AgendamentoValorTotal: parseFloat(ag.AgendamentoValorTotal),
                servicos: ag.servicos.map(s => s.servico)
            }));

            res.status(200).json({ 
                data: agendamentosFormatados,
                total: agendamentos.length
            });

        } catch (error) {
            console.error('Erro ao listar agendamentos:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Buscar agendamento por ID (apenas cliente ou prestador envolvidos)
    async buscarAgendamentoId(req, res) {
        try {
            const { agendamentoId } = req.params;

            const agendamento = await prisma.agendamento.findUnique({
                where: {
                    AgendamentoId: parseInt(agendamentoId)
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    },
                    cliente: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    },
                    servicos: {
                        include: {
                            servico: {
                                include: {
                                    precos: {
                                        orderBy: {
                                            ServicoPrecoDtCriacao: 'desc'
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            });

            if (!agendamento) {
                return res.status(404).json({ error: 'Agendamento não encontrado' });
            }

            // Verificar se o usuário tem permissão (é o cliente ou o prestador)
            if (agendamento.ClienteId !== req.usuario.usuarioId && 
                agendamento.PrestadorId !== req.usuario.usuarioId) {
                return res.status(403).json({ 
                    error: 'Você não tem permissão para visualizar este agendamento' 
                });
            }

            // Formatar resposta
            const respostaFormatada = {
                ...agendamento,
                AgendamentoValorTotal: parseFloat(agendamento.AgendamentoValorTotal),
                servicos: agendamento.servicos.map(sa => ({
                    ServicoAgendamentoId: sa.ServicoAgendamentoId,
                    servico: {
                        ...sa.servico,
                        precos: sa.servico.precos.map(p => ({
                            ...p,
                            ServicoValor: parseFloat(p.ServicoValor)
                        }))
                    }
                }))
            };

            res.status(200).json({ data: respostaFormatada });

        } catch (error) {
            console.error('Erro ao buscar agendamento:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Atualizar status do agendamento (cliente ou prestador)
    async atualizarStatus(req, res) {
        try {
            const agendamentoId = parseInt(req.params.id);
            const { AgendamentoStatus } = req.body;

            const statusValidos = ['PENDENTE', 'CONFIRMADO', 'EM_ANDAMENTO', 'CONCLUIDO', 'CANCELADO'];
            
            if (!AgendamentoStatus || !statusValidos.includes(AgendamentoStatus)) {
                return res.status(400).json({ 
                    error: 'Status inválido. Use: PENDENTE, CONFIRMADO, EM_ANDAMENTO, CONCLUIDO, CANCELADO' 
                });
            }

            // Buscar agendamento
            const agendamento = await prisma.agendamento.findUnique({
                where: { AgendamentoId: agendamentoId }
            });

            if (!agendamento) {
                return res.status(404).json({ error: 'Agendamento não encontrado' });
            }

            // Verificar permissão (cliente ou prestador)
            if (agendamento.ClienteId !== req.usuario.usuarioId && 
                agendamento.PrestadorId !== req.usuario.usuarioId) {
                return res.status(403).json({ 
                    error: 'Você não tem permissão para alterar este agendamento' 
                });
            }

            // Regras de transição de status
            const transicoesValidas = {
                'PENDENTE': ['CONFIRMADO', 'CANCELADO'],
                'CONFIRMADO': ['EM_ANDAMENTO', 'CANCELADO'],
                'EM_ANDAMENTO': ['CONCLUIDO'],
                'CONCLUIDO': [],
                'CANCELADO': []
            };

            if (!transicoesValidas[agendamento.AgendamentoStatus].includes(AgendamentoStatus)) {
                return res.status(400).json({ 
                    error: `Não é possível mudar de ${agendamento.AgendamentoStatus} para ${AgendamentoStatus}` 
                });
            }

            // Atualizar status
            const agendamentoAtualizado = await prisma.agendamento.update({
                where: { AgendamentoId: agendamentoId },
                data: { AgendamentoStatus },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true
                        }
                    },
                    cliente: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true
                        }
                    },
                    servicos: {
                        include: {
                            servico: {
                                select: {
                                    ServicoId: true,
                                    ServicoNome: true
                                }
                            }
                        }
                    }
                }
            });

            res.status(200).json({
                message: 'Status do agendamento atualizado com sucesso',
                data: {
                    ...agendamentoAtualizado,
                    AgendamentoValorTotal: parseFloat(agendamentoAtualizado.AgendamentoValorTotal)
                }
            });

        } catch (error) {
            console.error('Erro ao atualizar status:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Cancelar agendamento (apenas cliente ou prestador)
    async cancelarAgendamento(req, res) {
        try {
            const agendamentoId = parseInt(req.params.agendamentoId);

            // Buscar agendamento
            const agendamento = await prisma.agendamento.findUnique({
                where: { AgendamentoId: agendamentoId }
            });

            if (!agendamento) {
                return res.status(404).json({ error: 'Agendamento não encontrado' });
            }

            // Verificar permissão (cliente ou prestador)
            if (agendamento.ClienteId !== req.usuario.usuarioId && 
                agendamento.PrestadorId !== req.usuario.usuarioId) {
                return res.status(403).json({ 
                    error: 'Você não tem permissão para cancelar este agendamento' 
                });
            }

            // Verificar se pode cancelar
            if (agendamento.AgendamentoStatus === 'CONCLUIDO') {
                return res.status(400).json({ 
                    error: 'Não é possível cancelar um agendamento concluído' 
                });
            }

            if (agendamento.AgendamentoStatus === 'CANCELADO') {
                return res.status(400).json({ 
                    error: 'Agendamento já está cancelado' 
                });
            }

            // Cancelar agendamento
            const agendamentoCancelado = await prisma.agendamento.update({
                where: { AgendamentoId: agendamentoId },
                data: { AgendamentoStatus: 'CANCELADO' },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true
                        }
                    },
                    cliente: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true
                        }
                    }
                }
            });

            res.status(200).json({
                message: 'Agendamento cancelado com sucesso',
                data: {
                    ...agendamentoCancelado,
                    AgendamentoValorTotal: parseFloat(agendamentoCancelado.AgendamentoValorTotal)
                }
            });

        } catch (error) {
            console.error('Erro ao cancelar agendamento:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // Listar agendamentos por período (qualquer usuário logado - filtrado por permissão)
    async listarAgendamentosPorPeriodo(req, res) {
        try {
            const { dataInicio, dataFim } = req.query;

            if (!dataInicio || !dataFim) {
                return res.status(400).json({ 
                    error: 'Data de início e data de fim são obrigatórias' 
                });
            }

            const inicio = new Date(dataInicio);
            const fim = new Date(dataFim);

            // Construir where base
            const where = {
                AgendamentoDtServico: {
                    gte: inicio,
                    lte: fim
                }
            };

            // Filtrar por permissão
            if (req.usuario.usuarioTipo === 'CLIENTE') {
                where.ClienteId = req.usuario.usuarioId;
            } else if (req.usuario.usuarioTipo === 'PRESTADOR') {
                where.PrestadorId = req.usuario.usuarioId;
            }

            const agendamentos = await prisma.agendamento.findMany({
                where,
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true
                        }
                    },
                    cliente: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true
                        }
                    },
                    servicos: {
                        include: {
                            servico: {
                                select: {
                                    ServicoId: true,
                                    ServicoNome: true
                                }
                            }
                        }
                    }
                },
                orderBy: [
                    {
                        AgendamentoDtServico: 'asc'
                    },
                    {
                        AgendamentoHoraServico: 'asc'
                    }
                ]
            });

            // Formatar resposta
            const agendamentosFormatados = agendamentos.map(ag => ({
                ...ag,
                AgendamentoValorTotal: parseFloat(ag.AgendamentoValorTotal),
                servicos: ag.servicos.map(s => s.servico)
            }));

            res.status(200).json({ 
                data: agendamentosFormatados,
                total: agendamentos.length,
                periodo: {
                    inicio,
                    fim
                }
            });

        } catch (error) {
            console.error('Erro ao listar agendamentos por período:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }
}

module.exports = new AgendamentoController();