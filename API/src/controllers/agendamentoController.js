// src/controllers/agendamentoController.js
const prisma = require('../prisma.js');

class AgendamentoController {

    // Cadastrar agendamento (apenas CLIENTE)
    async cadastrarAgendamento(req, res) {
        try {
            const {
                PrestadorId,
                DisponibilidadeId,
                AgendamentoDtServico,
                AgendamentoHoraServico,
                AgendamentoObservacao,
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

            if (!DisponibilidadeId) {
                return res.status(400).json({ error: 'ID da disponibilidade é obrigatório' });
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

            // Verificar disponibilidade pelo ID específico
            const disponibilidade = await prisma.disponibilidade.findUnique({
                where: {
                    DisponibilidadeId: parseInt(DisponibilidadeId)
                }
            });

            if (!disponibilidade) {
                return res.status(400).json({
                    error: 'Disponibilidade não encontrada'
                });
            }

            // Verificar se a disponibilidade pertence ao prestador
            if (disponibilidade.PrestadorId !== parseInt(PrestadorId)) {
                return res.status(400).json({
                    error: 'Disponibilidade não pertence ao prestador informado'
                });
            }

            // Verificar se a disponibilidade está ativa
            if (!disponibilidade.DisponibilidadeStatus) {
                return res.status(400).json({
                    error: 'Disponibilidade inativa'
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
                        DisponibilidadeId: parseInt(DisponibilidadeId),
                        AgendamentoDtServico: dataServico,
                        AgendamentoHoraServico: AgendamentoHoraServico,
                        AgendamentoValorTotal: valorTotal,
                        AgendamentoTempoGasto: tempoTotal,
                        AgendamentoStatus: 'PENDENTE',
                        AgendamentoObservacao: AgendamentoObservacao || null
                    }
                });

                // Atualizar disponibilidade para INATIVA
                const disponibilidadeAtualizada = await prisma.disponibilidade.update({
                    where: { DisponibilidadeId: parseInt(DisponibilidadeId) },
                    data: { DisponibilidadeStatus: false }
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
    async listarMeusAgendamentosClientePendentes(req, res) {
        try {
            const agendamentos = await prisma.agendamento.findMany({
                where: {
                    ClienteId: req.usuario.usuarioId,
                    AgendamentoStatus: { in: ['PENDENTE', 'CONFIRMADO'] }// Exibir apenas agendamentos confirmados ou pendentes
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

    // Listar agendamentos do prestador logado (apenas PRESTADOR) com filtro de data
    async listarMeusAgendamentosPrestador(req, res) {
        try {
            // Verificar se é prestador
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem acessar esta rota'
                });
            }

            const { dataInicio, dataFim } = req.query;

            // Construir where dinâmico
            const where = {
                PrestadorId: req.usuario.usuarioId
            };

            // Aplicar filtro de data se fornecido
            if (dataInicio || dataFim) {
                where.AgendamentoDtServico = {};

                if (dataInicio) {
                    const inicio = new Date(dataInicio);
                    inicio.setHours(0, 0, 0, 0);
                    where.AgendamentoDtServico.gte = inicio;
                }

                if (dataFim) {
                    const fim = new Date(dataFim);
                    fim.setHours(23, 59, 59, 999);
                    where.AgendamentoDtServico.lte = fim;
                }
            }

            const agendamentos = await prisma.agendamento.findMany({
                where: where,
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
                total: agendamentos.length,
                periodo: dataInicio || dataFim ? { dataInicio, dataFim } : null
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

            const statusValidos = ['PENDENTE', 'CONFIRMADO', 'EM_ANDAMENTO', 'CONCLUIDO'];

            if (!AgendamentoStatus || !statusValidos.includes(AgendamentoStatus)) {
                return res.status(400).json({
                    error: 'Status inválido. Use: PENDENTE, CONFIRMADO, EM_ANDAMENTO, CONCLUIDO'
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
                'PENDENTE': ['CONFIRMADO'],
                'CONFIRMADO': ['EM_ANDAMENTO', 'PENDENTE'], // Permitir voltar para PENDENTE se necessário
                'EM_ANDAMENTO': ['CONCLUIDO'],
                'CONCLUIDO': []
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

    // Atualizar agendamento (apenas CLIENTE, apenas PENDENTE)
    async atualizarAgendamento(req, res) {
        try {
            const agendamentoId = parseInt(req.params.id);
            const {
                DisponibilidadeId, // NOVO: ID da disponibilidade selecionada
                AgendamentoDtServico,
                AgendamentoHoraServico,
                AgendamentoObservacao,
                servicos // Array de IDs dos serviços
            } = req.body;

            // Buscar agendamento existente
            const agendamentoExistente = await prisma.agendamento.findUnique({
                where: { AgendamentoId: agendamentoId },
                include: {
                    servicos: true
                }
            });

            if (!agendamentoExistente) {
                return res.status(404).json({ error: 'Agendamento não encontrado' });
            }

            // Verificar permissão (apenas o cliente dono do agendamento)
            if (agendamentoExistente.ClienteId !== req.usuario.usuarioId) {
                return res.status(403).json({
                    error: 'Você só pode editar seus próprios agendamentos'
                });
            }

            // Verificar se o agendamento está em status que permite edição
            if (agendamentoExistente.AgendamentoStatus !== 'PENDENTE') {
                return res.status(400).json({
                    error: 'Apenas agendamentos com status PENDENTE podem ser editados'
                });
            }

            // Validações básicas
            if (AgendamentoDtServico) {
                const dataServico = new Date(AgendamentoDtServico);
                const hoje = new Date();
                hoje.setHours(0, 0, 0, 0);

                if (dataServico < hoje) {
                    return res.status(400).json({ error: 'A data do serviço deve ser futura' });
                }
            }

            if (AgendamentoHoraServico) {
                const horaRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
                if (!horaRegex.test(AgendamentoHoraServico)) {
                    return res.status(400).json({ error: 'Hora do serviço deve estar no formato HH:MM (ex: 14:30)' });
                }
            }

            // NOVA LÓGICA: Verificar se a disponibilidade foi alterada
            const disponibilidadeAlterada = DisponibilidadeId &&
                DisponibilidadeId !== agendamentoExistente.DisponibilidadeId;

            if (disponibilidadeAlterada) {
                // Verificar se a nova disponibilidade existe e está ativa
                const novaDisponibilidade = await prisma.disponibilidade.findUnique({
                    where: { DisponibilidadeId: parseInt(DisponibilidadeId) }
                });

                if (!novaDisponibilidade) {
                    return res.status(400).json({
                        error: 'Disponibilidade não encontrada'
                    });
                }

                if (!novaDisponibilidade.DisponibilidadeStatus) {
                    return res.status(400).json({
                        error: 'Disponibilidade selecionada não está mais disponível'
                    });
                }

                // Verificar se a nova disponibilidade pertence ao mesmo prestador
                if (novaDisponibilidade.PrestadorId !== agendamentoExistente.PrestadorId) {
                    return res.status(400).json({
                        error: 'Disponibilidade não pertence ao prestador do agendamento'
                    });
                }

                // Verificar se a data/hora da nova disponibilidade corresponde à selecionada
                /*if (AgendamentoDtServico || AgendamentoHoraServico) {
                    const dataComparar = AgendamentoDtServico
                        ? new Date(AgendamentoDtServico)
                        : agendamentoExistente.AgendamentoDtServico;

                    const horaComparar = AgendamentoHoraServico || agendamentoExistente.AgendamentoHoraServico;

                    // Verificar se a disponibilidade cobre o horário selecionado
                    if (novaDisponibilidade.DisponibilidadeData.toDateString() !== dataComparar.toDateString() ||
                        novaDisponibilidade.DisponibilidadeHoraInicio > horaComparar ||
                        novaDisponibilidade.DisponibilidadeHoraFim <= horaComparar) {
                        return res.status(400).json({
                            error: 'A disponibilidade selecionada não corresponde ao horário escolhido'
                        });
                    }
                }*/
            }

            // Se houver alteração de data/hora (mesmo sem mudar disponibilidade), verificar disponibilidade
            if (!disponibilidadeAlterada && (AgendamentoDtServico || AgendamentoHoraServico)) {
                const novaData = AgendamentoDtServico
                    ? new Date(AgendamentoDtServico)
                    : agendamentoExistente.AgendamentoDtServico;

                const novaHora = AgendamentoHoraServico || agendamentoExistente.AgendamentoHoraServico;

                // Verificar se a disponibilidade original ainda cobre o novo horário
                const disponibilidadeOriginal = await prisma.disponibilidade.findUnique({
                    where: { DisponibilidadeId: agendamentoExistente.DisponibilidadeId }
                });

                if (!disponibilidadeOriginal || !disponibilidadeOriginal.DisponibilidadeStatus) {
                    return res.status(400).json({
                        error: 'A disponibilidade original não está mais disponível'
                    });
                }

                if (disponibilidadeOriginal.DisponibilidadeData.toDateString() !== novaData.toDateString() ||
                    disponibilidadeOriginal.DisponibilidadeHoraInicio > novaHora ||
                    disponibilidadeOriginal.DisponibilidadeHoraFim <= novaHora) {
                    return res.status(400).json({
                        error: 'O novo horário não é coberto pela disponibilidade original'
                    });
                }
            }

            // Verificar conflito de horário com outros agendamentos (excluindo o atual)
            const novaData = AgendamentoDtServico
                ? new Date(AgendamentoDtServico)
                : agendamentoExistente.AgendamentoDtServico;

            const novaHora = AgendamentoHoraServico || agendamentoExistente.AgendamentoHoraServico;

            const conflito = await prisma.agendamento.findFirst({
                where: {
                    PrestadorId: agendamentoExistente.PrestadorId,
                    AgendamentoId: { not: agendamentoId },
                    AgendamentoDtServico: novaData,
                    AgendamentoHoraServico: novaHora,
                    AgendamentoStatus: { notIn: ['CANCELADO', 'CONCLUIDO'] }
                }
            });

            if (conflito) {
                return res.status(409).json({
                    error: 'Já existe um agendamento para este horário'
                });
            }

            // Se houver alteração nos serviços, recalcular totais
            let valorTotal = agendamentoExistente.AgendamentoValorTotal;
            let tempoTotal = agendamentoExistente.AgendamentoTempoGasto;

            if (servicos && servicos.length > 0) {
                // Buscar serviços com preços atuais
                const servicosEncontrados = await prisma.servico.findMany({
                    where: {
                        ServicoId: { in: servicos.map(id => parseInt(id)) },
                        PrestadorId: agendamentoExistente.PrestadorId,
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

                // Recalcular totais
                valorTotal = 0;
                tempoTotal = 0;

                servicosEncontrados.forEach(servico => {
                    if (servico.precos && servico.precos.length > 0) {
                        valorTotal += parseFloat(servico.precos[0].ServicoValor);
                    }
                    tempoTotal += servico.ServicoTempoMedio;
                });
            }

            // Atualizar agendamento em transação
            const resultado = await prisma.$transaction(async (prisma) => {
                // Se a disponibilidade foi alterada
                if (disponibilidadeAlterada) {
                    // Reativar a disponibilidade antiga
                    await prisma.disponibilidade.update({
                        where: { DisponibilidadeId: agendamentoExistente.DisponibilidadeId },
                        data: { DisponibilidadeStatus: true }
                    });

                    // Desativar a nova disponibilidade
                    await prisma.disponibilidade.update({
                        where: { DisponibilidadeId: parseInt(DisponibilidadeId) },
                        data: { DisponibilidadeStatus: false }
                    });
                }

                // Se os serviços foram alterados, remover os antigos e adicionar os novos
                if (servicos && servicos.length > 0) {
                    // Remover relações antigas
                    await prisma.servicoAgendamento.deleteMany({
                        where: { AgendamentoId: agendamentoId }
                    });

                    // Adicionar novas relações
                    await Promise.all(
                        servicos.map(servicoId =>
                            prisma.servicoAgendamento.create({
                                data: {
                                    AgendamentoId: agendamentoId,
                                    ServicoId: parseInt(servicoId)
                                }
                            })
                        )
                    );
                }

                // Atualizar agendamento
                const agendamentoAtualizado = await prisma.agendamento.update({
                    where: { AgendamentoId: agendamentoId },
                    data: {
                        DisponibilidadeId: disponibilidadeAlterada
                            ? parseInt(DisponibilidadeId)
                            : agendamentoExistente.DisponibilidadeId,
                        AgendamentoDtServico: AgendamentoDtServico
                            ? new Date(AgendamentoDtServico)
                            : agendamentoExistente.AgendamentoDtServico,
                        AgendamentoHoraServico: AgendamentoHoraServico || agendamentoExistente.AgendamentoHoraServico,
                        AgendamentoValorTotal: valorTotal,
                        AgendamentoTempoGasto: tempoTotal,
                        AgendamentoObservacao: AgendamentoObservacao !== undefined
                            ? AgendamentoObservacao
                            : agendamentoExistente.AgendamentoObservacao
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
                                            },
                                            take: 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                });

                return agendamentoAtualizado;
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

            res.status(200).json({
                message: 'Agendamento atualizado com sucesso',
                data: respostaFormatada
            });

        } catch (error) {
            console.error('Erro ao atualizar agendamento:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Cancelar/Recusar agendamento (apenas cliente ou prestador)
    async cancelarAgendamento(req, res) {
        try {
            const agendamentoId = parseInt(req.params.agendamentoId);
            const { motivo } = req.body; // Receber motivo do cancelamento/recusa

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

            let tipoUsuario;
            let tipoCancelamento;
            if (agendamento.ClienteId === req.usuario.usuarioId) {
                tipoUsuario = 'CLIENTE';
                tipoCancelamento = 'CANCELADO';
            } else {
                tipoUsuario = 'PRESTADOR';
                tipoCancelamento = 'RECUSADO';
            }

            // Verificar se pode cancelar
            if (agendamento.AgendamentoStatus === 'CONCLUIDO') {
                return res.status(400).json({
                    error: 'Não é possível cancelar um agendamento concluído'
                });
            }

            if (agendamento.AgendamentoStatus === 'EM_ANDAMENTO') {
                return res.status(400).json({
                    error: 'Não é possível cancelar um agendamento em andamento'
                });
            }

            if (agendamento.AgendamentoStatus === 'CANCELADO' || agendamento.AgendamentoStatus === 'RECUSADO') {
                return res.status(400).json({
                    error: 'Agendamento já está cancelado'
                });
            }

            if (agendamento.AgendamentoStatus === 'CONFIRMADO' && tipoUsuario === 'PRESTADOR') {
                return res.status(400).json({
                    error: 'Agendamento confirmado não pode ser cancelado pelo prestador.'
                });
            }

            // Validar motivo para recusa/cancelamento
            if (!motivo || motivo.trim() === '') {
                return res.status(400).json({
                    error: tipoCancelamento === 'RECUSADO'
                        ? 'É necessário informar o motivo da recusa'
                        : 'É necessário informar o motivo do cancelamento'
                });
            }

            // Cancelar agendamento com motivo
            const agendamentoCancelado = await prisma.agendamento.update({
                where: { AgendamentoId: agendamentoId },
                data: {
                    AgendamentoStatus: tipoCancelamento,
                    AgendamentoDescricaoTrabalho: motivo.trim() // Salvar motivo no campo de descrição
                },
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

            // Reativar disponibilidade associada
            await prisma.disponibilidade.update({
                where: { DisponibilidadeId: agendamento.DisponibilidadeId },
                data: { DisponibilidadeStatus: true }
            });

            res.status(200).json({
                message: tipoCancelamento === 'RECUSADO'
                    ? 'Agendamento recusado com sucesso'
                    : 'Agendamento cancelado com sucesso',
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