// src/controllers/agendamentoController.js
const prisma = require('../prisma.js');
const crypto = require('crypto');

class AgendamentoController {

    // Rota para gravar quando usuários iniciam um agendamento, mesmo sem te-lo finalizado (Testes AB)
    async iniciarAgendamento(req, res) {
        try {
            const {
                Tela
            } = req.body;

            let LogAcao = '';
            switch (Tela) {
                case 'MOBILE_PESQUISA': LogAcao = 'AGENBTNPES'
                case 'MOBILE_BTNCENTRAL': LogAcao = 'AGENBTNCEN'
                case 'MOBILE_BTNTELAHOME': LogAcao = 'AGENBTNTELA'
            }

            // Verificar se o usuário é CLIENTE
            if (req.usuario.usuarioTipo !== 'CLIENTE') {
                return res.status(403).json({
                    error: 'Apenas clientes podem realizar agendamentos'
                });
            }

            const usuarioId = req.usuario.usuarioId;

            const uuid = crypto.randomUUID();

            // Adicionar registro na tabela log
            await prisma.log.create({
                data: {
                    UsuEmpId: usuarioId,
                    LogAcao: LogAcao,
                    TipoRelacao: 'USUARIO',
                    LogDetalhe: uuid,
                    LogData: new Date()
                }
            });

            res.status(201).json({
                message: 'Registro de inicio de agendamento criado com sucesso',
                uuid: uuid,
                tela: LogAcao
            });

        } catch (error) {
            console.error('Erro ao registrar início de agendamento:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Cadastrar agendamento (apenas CLIENTE)
    async cadastrarAgendamento(req, res) {
        try {
            const {
                PrestadorId,
                DisponibilidadeId,
                AgendamentoDtServico,
                AgendamentoHoraServico,
                AgendamentoObservacao,
                servicos, // Array de IDs dos serviços
                uuid
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
                    AgendamentoStatus: { notIn: ['CANCELADO', 'CONCLUIDO', 'RECUSADO'] }
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

            // Obtem o ID do estabelecimento na disponibilidade, se houver
            const estabelecimentoId = disponibilidade.EstabelecimentoId;

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
                        AgendamentoObservacao: AgendamentoObservacao || null,
                        EstabelecimentoId: estabelecimentoId
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
                                ServicoId: servico.ServicoId,
                                ServicoValor: servico.precos[0].ServicoValor
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

            // Adicionar registro de finalização na tabela log

            if (uuid) {
                const usuarioId = req.usuario.usuarioId;
                await prisma.log.create({
                    data: {
                        UsuEmpId: usuarioId,
                        LogAcao: 'FIMAGEN',
                        TipoRelacao: 'USUARIO',
                        LogDetalhe: uuid,
                        LogData: new Date()
                    }
                });
            }

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
                    },
                    estabelecimento: {
                        include: {
                            empresa: {
                                select: {
                                    EmpresaNome: true
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
                total: agendamentos.length
            });

        } catch (error) {
            console.error('Erro ao listar agendamentos:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Listar todos os agendamentos do cliente com filtro de período
    async listarMeusAgendamentosClienteTodos(req, res) {
        try {
            const { dataInicio, dataFim, status } = req.query;

            // Definir período padrão (último ano + três meses)
            const hoje = new Date();
            const inicioPadrao = new Date(hoje.getFullYear() - 1, hoje.getMonth(), hoje.getDate());
            const fimPadrao = new Date(hoje.getFullYear(), hoje.getMonth() + 3, hoje.getDate(), 23, 59, 59);

            // Construir where dinâmico
            const where = {
                ClienteId: req.usuario.usuarioId
            };

            // Aplicar filtro de período
            if (dataInicio && dataFim) {
                const inicio = new Date(dataInicio);
                inicio.setHours(0, 0, 0, 0);
                const fim = new Date(dataFim);
                fim.setHours(23, 59, 59, 999);
                where.AgendamentoDtServico = {
                    gte: inicio,
                    lte: fim
                };
            } else {
                // Período padrão: último ano
                where.AgendamentoDtServico = {
                    gte: inicioPadrao,
                    lte: fimPadrao
                };
            }

            // Aplicar filtro de status se fornecido
            if (status) {
                where.AgendamentoStatus = status;
            }

            const agendamentos = await prisma.agendamento.findMany({
                where,
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
                        },
                    },
                    estabelecimento: {
                        include: {
                            empresa: {
                                select: {
                                    EmpresaNome: true
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
                    },
                    {
                        AgendamentoDtCriacao: 'desc'
                    }
                ]
            });

            //console.log('agendamentos = ', agendamentos);

            // Formatar resposta
            const agendamentosFormatados = agendamentos.map(ag => ({
                ...ag,
                AgendamentoValorTotal: parseFloat(ag.AgendamentoValorTotal),
                servicos: ag.servicos.map(s => ({
                    ServicoAgendamentoId: s.ServicoAgendamentoId,
                    ServicoId: s.ServicoId,
                    ServicoValor: parseFloat(s.ServicoValor),
                    AgendamentoId: s.AgendamentoId,
                    servico: s.servico
                }))
            }));

            console.log('agendamentosFormatados = ', JSON.stringify(agendamentosFormatados, null, 2));

            res.status(200).json({
                success: true,
                data: agendamentosFormatados,
                total: agendamentos.length,
                periodo: {
                    dataInicio: dataInicio || inicioPadrao.toISOString().split('T')[0],
                    dataFim: dataFim || fimPadrao.toISOString().split('T')[0]
                }
            });

        } catch (error) {
            console.error('Erro ao listar agendamentos do cliente:', error);
            res.status(500).json({
                success: false,
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
                servicos: ag.servicos.map(s => ({
                    ServicoAgendamentoId: s.ServicoAgendamentoId,
                    ServicoId: s.ServicoId,
                    ServicoValor: parseFloat(s.ServicoValor),
                    AgendamentoId: s.AgendamentoId,
                    servico: s.servico
                }))
            }));

            //console.log('agendamentosFormatados = ', agendamentosFormatados);
            //console.log('Agendamentos:', JSON.stringify(agendamentos, null, 2));

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

    // Listar agendamentos dos estabelecimentos da empresa
    async listarAgendamentosEmpresa(req, res) {
        try {
            const empresaId = req.usuario.usuarioId;
            const { estabelecimentoId, dataInicio, dataFim, status } = req.query;

            // Verificar se é empresa
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem acessar esta rota'
                });
            }

            // Buscar estabelecimentos da empresa
            const whereEstabelecimentos = { EmpresaId: empresaId };
            if (estabelecimentoId) {
                whereEstabelecimentos.EstabelecimentoId = parseInt(estabelecimentoId);
            }

            const estabelecimentos = await prisma.estabelecimento.findMany({
                where: whereEstabelecimentos,
                select: { EstabelecimentoId: true }
            });

            const estabelecimentoIds = estabelecimentos.map(e => e.EstabelecimentoId);

            if (estabelecimentoIds.length === 0) {
                return res.status(200).json({ data: [], total: 0 });
            }

            // Construir where dinâmico
            const where = {
                EstabelecimentoId: { in: estabelecimentoIds }
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

            // Aplicar filtro de status se fornecido
            if (status) {
                where.AgendamentoStatus = status;
            }

            const agendamentos = await prisma.agendamento.findMany({
                where: where,
                include: {
                    cliente: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioTelefone: true
                        }
                    },
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true
                        }
                    },
                    estabelecimento: {
                        select: {
                            EstabelecimentoNome: true
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
                    { AgendamentoDtServico: 'desc' },
                    { AgendamentoHoraServico: 'desc' }
                ]
            });

            // Formatar resposta
            const agendamentosFormatados = agendamentos.map(ag => ({
                ...ag,
                AgendamentoValorTotal: parseFloat(ag.AgendamentoValorTotal),
                servicos: ag.servicos.map(s => ({
                    ServicoAgendamentoId: s.ServicoAgendamentoId,
                    ServicoId: s.ServicoId,
                    ServicoValor: parseFloat(s.ServicoValor),
                    AgendamentoId: s.AgendamentoId,
                    servico: s.servico
                }))
            }));

            //console.log('agendamentosFormatados:', JSON.stringify(agendamentosFormatados, null, 2));

            res.status(200).json({
                data: agendamentosFormatados,
                total: agendamentos.length,
                periodo: dataInicio || dataFim ? { dataInicio, dataFim } : null
            });

        } catch (error) {
            console.error('Erro ao listar agendamentos da empresa:', error);
            res.status(500).json({ error: error.message });
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
                            UsuarioTelefone: true
                        }
                    },
                    cliente: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
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
                    },
                    estabelecimento: {
                        include: {
                            empresa: {
                                select: {
                                    EmpresaNome: true,
                                    EmpresaId: true
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
            if ((agendamento.ClienteId === req.usuario.usuarioId && req.usuario.usuarioTipo === 'CLIENTE') ||
                (agendamento.PrestadorId === req.usuario.usuarioId && req.usuario.usuarioTipo === 'PRESTADOR') || (agendamento.estabelecimento.empresa.EmpresaId === req.usuario.usuarioId && req.usuario.usuarioTipo === 'EMPRESA')) {
            } else {
                return res.status(403).json({
                    error: 'Você não tem permissão para visualizar este agendamento'
                });
            }

            let endereco;
            //console.log('agendamento.EstabelecimentoId = ', agendamento.EstabelecimentoId);
            if (agendamento.EstabelecimentoId) {
                endereco = await prisma.endereco.findFirst({
                    where: {
                        UsuEstId: agendamento.EstabelecimentoId,
                        TipoRelacao: 'ESTABELECIMENTO'
                    },
                });
            } else if (agendamento.PrestadorId) {
                endereco = await prisma.endereco.findFirst({
                    where: {
                        UsuEstId: agendamento.PrestadorId,
                        TipoRelacao: 'USUARIO'
                    },
                });
            }

            //Rua 7, N° 1234 B, Jardim Rotatória, Sales Oliveira - SP. Complemento...
            const enderecoFormatado = endereco.EnderecoRua + ', N° ' + endereco.EnderecoNumero + ', ' + endereco.EnderecoBairro + ', ' + endereco.EnderecoCidade + ' - ' + endereco.EnderecoEstado + '. \n' + endereco.EnderecoComplemento

            let contatoTelefone;
            if (agendamento.EstabelecimentoId) {
                contatoTelefone = agendamento.estabelecimento.EstabelecimentoTelefone;
            } else {
                contatoTelefone = agendamento.prestador.UsuarioTelefone;
            }

            // Formatar resposta - USAR O VALOR ARMAZENADO NO ServicoAgendamento
            const respostaFormatada = {
                ...agendamento,
                AgendamentoValorTotal: parseFloat(agendamento.AgendamentoValorTotal),
                servicos: agendamento.servicos.map(sa => ({
                    ServicoAgendamentoId: sa.ServicoAgendamentoId,
                    ServicoValor: parseFloat(sa.ServicoValor),
                    servico: {
                        ServicoId: sa.servico.ServicoId,
                        ServicoNome: sa.servico.ServicoNome,
                        ServicoDescricao: sa.servico.ServicoDescricao,
                        ServicoTempoMedio: sa.servico.ServicoTempoMedio,
                        valorNoMomento: parseFloat(sa.ServicoValor)
                    }
                })),
                endereco: enderecoFormatado,
                contatoTelefone: contatoTelefone
            };

            //console.log('respostaFormatada = ', respostaFormatada);

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
            const { AgendamentoStatus, AgendamentoDescricaoTrabalho } = req.body;

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
                data: { AgendamentoStatus: AgendamentoStatus, AgendamentoDescricaoTrabalho: AgendamentoDescricaoTrabalho || null },
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

                    // Adicionar novas relações com os preços atuais
                    await Promise.all(
                        servicos.map(async (servicoId) => {
                            // Buscar o preço atual do serviço
                            const servico = await prisma.servico.findUnique({
                                where: { ServicoId: parseInt(servicoId) },
                                include: {
                                    precos: {
                                        orderBy: {
                                            ServicoPrecoDtCriacao: 'desc'
                                        },
                                        take: 1
                                    }
                                }
                            });

                            // Obter o preço atual (mais recente) ou 0 se não houver
                            const precoAtual = servico?.precos?.[0]?.ServicoValor ?? 0;

                            // Criar a relação com o preço registrado
                            return prisma.servicoAgendamento.create({
                                data: {
                                    AgendamentoId: agendamentoId,
                                    ServicoId: parseInt(servicoId),
                                    ServicoValor: precoAtual
                                }
                            });
                        })
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

    // Buscar últimas empresas com agendamentos do cliente
    async buscarUltimasEmpresas(req, res) {
        try {
            const clienteId = req.usuario.usuarioId;

            // Buscar os 3 agendamentos mais recentes do cliente com estabelecimento
            const agendamentos = await prisma.agendamento.findMany({
                where: {
                    ClienteId: clienteId,
                    EstabelecimentoId: { not: null }
                },
                include: {
                    estabelecimento: {
                        include: {
                            empresa: {
                                select: {
                                    EmpresaId: true,
                                    EmpresaNome: true,
                                    EmpresaTelefone: true
                                }
                            }
                        }
                    }
                },
                orderBy: {
                    AgendamentoDtServico: 'desc'
                },
                distinct: ['EstabelecimentoId'],
                take: 3
            });

            // Extrair empresas únicas
            const empresasMap = new Map();
            agendamentos.forEach(ag => {
                const empresa = ag.estabelecimento?.empresa;
                if (empresa && !empresasMap.has(empresa.EmpresaId)) {
                    empresasMap.set(empresa.EmpresaId, {
                        id: empresa.EmpresaId,
                        nome: empresa.EmpresaNome,
                        telefone: empresa.EmpresaTelefone
                    });
                }
            });

            res.status(200).json({
                success: true,
                data: Array.from(empresasMap.values())
            });

        } catch (error) {
            console.error('Erro ao buscar últimas empresas:', error);
            res.status(500).json({ error: error.message });
        }
    }

}

module.exports = new AgendamentoController();