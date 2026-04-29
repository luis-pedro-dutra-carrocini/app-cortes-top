const prisma = require('../prisma.js');

class ServicoEstabelecimentoController {

    // Cadastrar serviço do estabelecimento (apenas EMPRESA)
    async cadastrarServicoEstabelecimento(req, res) {
        try {
            const {
                EstabelecimentoId,
                ServicoNome,
                ServicoDescricao,
                ServicoTempoMedio,
                ServicoAtivo = true
            } = req.body;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem cadastrar serviços para estabelecimentos'
                });
            }

            // Validações
            if (!EstabelecimentoId) {
                return res.status(400).json({ error: 'ID do estabelecimento é obrigatório' });
            }

            if (!ServicoNome || ServicoNome.trim() === '') {
                return res.status(400).json({ error: 'Nome do serviço é obrigatório' });
            }

            if (!ServicoTempoMedio || ServicoTempoMedio <= 0) {
                return res.status(400).json({ error: 'Tempo médio é obrigatório e deve ser maior que zero' });
            }

            // Verificar se o estabelecimento existe e pertence à empresa
            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: parseInt(EstabelecimentoId),
                    EmpresaId: req.usuario.usuarioId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({
                    error: 'Estabelecimento não encontrado ou não pertence à sua empresa'
                });
            }

            // Verificar se já existe serviço com mesmo nome no estabelecimento
            const servicoExistente = await prisma.servicoEstabelecimento.findFirst({
                where: {
                    EstabelecimentoId: parseInt(EstabelecimentoId),
                    ServicoNome: ServicoNome.trim()
                }
            });

            if (servicoExistente) {
                return res.status(409).json({
                    error: 'Já existe um serviço com este nome neste estabelecimento'
                });
            }

            // Criar serviço do estabelecimento
            const servico = await prisma.servicoEstabelecimento.create({
                data: {
                    EstabelecimentoId: parseInt(EstabelecimentoId),
                    ServicoNome: ServicoNome.trim(),
                    ServicoDescricao: ServicoDescricao ? ServicoDescricao.trim() : null,
                    ServicoTempoMedio: parseInt(ServicoTempoMedio),
                    ServicoAtivo: ServicoAtivo
                },
                include: {
                    estabelecimento: {
                        select: {
                            EstabelecimentoId: true,
                            EstabelecimentoNome: true,
                            empresa: {
                                select: {
                                    EmpresaId: true,
                                    EmpresaNome: true
                                }
                            }
                        }
                    }
                }
            });

            res.status(201).json({
                message: 'Serviço do estabelecimento cadastrado com sucesso',
                data: servico
            });

        } catch (error) {
            console.error('Erro ao cadastrar serviço do estabelecimento:', error);
            res.status(500).json({
                error: 'Erro ao cadastrar serviço do estabelecimento'
            });
        }
    }

    // Listar serviços de um estabelecimento (qualquer usuário logado)
    async listarServicosPorEstabelecimento(req, res) {
        try {
            const { estabelecimentoId } = req.params;

            if (!estabelecimentoId) {
                return res.status(400).json({ error: 'ID do estabelecimento é obrigatório' });
            }

            // Verificar se o estabelecimento existe
            const estabelecimento = await prisma.estabelecimento.findUnique({
                where: { EstabelecimentoId: parseInt(estabelecimentoId) }
            });

            if (!estabelecimento) {
                return res.status(404).json({ error: 'Estabelecimento não encontrado' });
            }

            // Buscar serviços do estabelecimento
            const servicos = await prisma.servicoEstabelecimento.findMany({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId)
                },
                include: {
                    estabelecimento: {
                        select: {
                            EstabelecimentoId: true,
                            EstabelecimentoNome: true
                        }
                    },
                    _count: {
                        select: {
                            servicos: {
                                where: {
                                    ServicoAtivo: true
                                }
                            }
                        }
                    }
                },
                orderBy: {
                    ServicoNome: 'asc'
                }
            });

            //console.log('servicos | ', servicos);

            res.status(200).json({
                data: servicos,
                estabelecimento: {
                    id: estabelecimento.EstabelecimentoId,
                    nome: estabelecimento.EstabelecimentoNome
                }
            });

        } catch (error) {
            console.error('Erro ao listar serviços do estabelecimento:', error);
            res.status(500).json({
                error: 'Erro ao listar serviços do estabelecimento'
            });
        }
    }

    // Listar todos os serviços de um estabelecimento (incluindo inativos) - apenas EMPRESA dona
    async listarTodosServicosPorEstabelecimento(req, res) {
        try {
            const { estabelecimentoId } = req.params;

            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem listar todos os serviços'
                });
            }

            // Verificar se o estabelecimento pertence à empresa
            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    EmpresaId: req.usuario.usuarioId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({
                    error: 'Estabelecimento não encontrado ou não pertence à sua empresa'
                });
            }

            // Buscar serviços do estabelecimento com informações de preços
            const servicos = await prisma.servicoEstabelecimento.findMany({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId)
                },
                include: {
                    estabelecimento: {
                        select: {
                            EstabelecimentoId: true,
                            EstabelecimentoNome: true
                        }
                    },
                    _count: {
                        select: {
                            servicos: {
                                where: {
                                    ServicoAtivo: true
                                }
                            }
                        }
                    },
                    servicos: {  // Incluir os serviços vinculados a prestadores
                        include: {
                            precos: {
                                orderBy: {
                                    ServicoPrecoDtCriacao: 'desc'
                                },
                                take: 1  // Pega apenas o preço mais recente de cada prestador
                            }
                        }
                    }
                },
                orderBy: {
                    ServicoNome: 'asc'
                }
            });

            // Processar cada serviço para calcular preços mínimo e máximo
            const servicosFormatados = servicos.map(servico => {
                let precoMin = null;
                let precoMax = null;

                // Extrair preços atuais de todos os prestadores vinculados ativos
                if (servico.servicos && servico.servicos.length > 0) {
                    // Filtrar apenas prestadores ativos
                    const prestadoresAtivos = servico.servicos.filter(s => s.ServicoAtivo === true);

                    if (prestadoresAtivos.length > 0) {
                        // Pegar o preço mais recente de cada prestador ativo
                        const precosAtuais = prestadoresAtivos
                            .map(s => s.precos && s.precos.length > 0 ? parseFloat(s.precos[0].ServicoValor) : null)
                            .filter(p => p !== null);

                        if (precosAtuais.length > 0) {
                            precoMin = Math.min(...precosAtuais);
                            precoMax = Math.max(...precosAtuais);
                        }
                    }
                }

                // Remover os dados detalhados dos serviços para não sobrecarregar a resposta
                const { servicos: _, ...servicoSemDetalhes } = servico;

                return {
                    ...servicoSemDetalhes,
                    precoMin: precoMin,
                    precoMax: precoMax,
                    faixaPreco: precoMin !== null && precoMax !== null
                        ? (precoMin === precoMax
                            ? `R$ ${precoMin.toFixed(2)}`
                            : `R$ ${precoMin.toFixed(2)} à R$ ${precoMax.toFixed(2)}`)
                        : 'Preço não definido'
                };
            });

            //console.log('servicosFormatados | ', servicosFormatados);

            res.status(200).json({
                data: servicosFormatados,
                estabelecimento: {
                    id: estabelecimento.EstabelecimentoId,
                    nome: estabelecimento.EstabelecimentoNome
                }
            });

        } catch (error) {
            console.error('Erro ao listar serviços do estabelecimento:', error);
            res.status(500).json({
                error: 'Erro ao listar serviços do estabelecimento'
            });
        }
    }

    // Buscar serviço do estabelecimento por ID
    async buscarServicoEstabelecimentoId(req, res) {
        try {
            const { servicoEstabelecimentoId } = req.params;

            const servico = await prisma.servicoEstabelecimento.findUnique({
                where: {
                    ServicoEstabelecimentoId: parseInt(servicoEstabelecimentoId)
                },
                include: {
                    estabelecimento: {
                        select: {
                            EstabelecimentoId: true,
                            EstabelecimentoNome: true,
                            empresa: {
                                select: {
                                    EmpresaId: true,
                                    EmpresaNome: true
                                }
                            }
                        }
                    },
                    servicos: {
                        include: {
                            prestador: {
                                select: {
                                    UsuarioId: true,
                                    UsuarioNome: true,
                                    UsuarioEmail: true
                                }
                            },
                            precos: {
                                orderBy: {
                                    ServicoPrecoDtCriacao: 'desc'
                                },
                                take: 1
                            }
                        }
                    }
                }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            res.status(200).json({ data: servico });

        } catch (error) {
            console.error('Erro ao buscar serviço:', error);
            res.status(500).json({
                error: 'Erro ao buscar serviço'
            });
        }
    }

    // Atualizar serviço do estabelecimento (apenas EMPRESA dona)
    async atualizarServicoEstabelecimento(req, res) {
        try {
            const servicoId = parseInt(req.params.id);
            const {
                ServicoNome,
                ServicoDescricao,
                ServicoTempoMedio,
                ServicoAtivo
            } = req.body;

            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem atualizar serviços do estabelecimento'
                });
            }

            // Buscar o serviço
            const servico = await prisma.servicoEstabelecimento.findUnique({
                where: { ServicoEstabelecimentoId: servicoId },
                include: {
                    estabelecimento: true
                }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            // Verificar se o estabelecimento pertence à empresa
            if (servico.estabelecimento.EmpresaId !== req.usuario.usuarioId) {
                return res.status(403).json({
                    error: 'Você só pode atualizar serviços dos seus estabelecimentos'
                });
            }

            // Validações
            if (ServicoTempoMedio && ServicoTempoMedio <= 0) {
                return res.status(400).json({ error: 'Tempo médio deve ser maior que zero' });
            }

            // Verificar nome duplicado
            if (ServicoNome && ServicoNome.trim() !== servico.ServicoNome) {
                const servicoExistente = await prisma.servicoEstabelecimento.findFirst({
                    where: {
                        EstabelecimentoId: servico.estabelecimento.EstabelecimentoId,
                        ServicoNome: ServicoNome.trim(),
                        ServicoEstabelecimentoId: { not: servicoId }
                    }
                });

                if (servicoExistente) {
                    return res.status(409).json({
                        error: 'Já existe um serviço com este nome neste estabelecimento'
                    });
                }
            }

            // Atualizar serviço
            const servicoAtualizado = await prisma.servicoEstabelecimento.update({
                where: {
                    ServicoEstabelecimentoId: servicoId
                },
                data: {
                    ServicoNome: ServicoNome ? ServicoNome.trim() : servico.ServicoNome,
                    ServicoDescricao: ServicoDescricao !== undefined ?
                        (ServicoDescricao ? ServicoDescricao.trim() : null) : servico.ServicoDescricao,
                    ServicoTempoMedio: ServicoTempoMedio ? parseInt(ServicoTempoMedio) : servico.ServicoTempoMedio,
                    ServicoAtivo: ServicoAtivo !== undefined ? ServicoAtivo : servico.ServicoAtivo
                }
            });

            // Atualizar os dados nos serviços vinculados
            await prisma.servico.updateMany({
                where: {
                    ServicoEstabelecimentoId: servicoId
                },
                data: {
                    ServicoDescricao: servicoAtualizado.ServicoDescricao,
                    ServicoTempoMedio: servicoAtualizado.ServicoTempoMedio,
                    ServicoNome: servicoAtualizado.ServicoNome
                }
            });

            res.status(200).json({
                message: 'Serviço do estabelecimento atualizado com sucesso',
                data: servicoAtualizado
            });

        } catch (error) {
            console.error('Erro ao atualizar serviço:', error);
            res.status(500).json({
                error: 'Erro ao atualizar serviço'
            });
        }
    }

    // Vincular serviço do estabelecimento a um prestador
    async vincularServicoAPrestador(req, res) {
        try {
            const { servicoEstabelecimentoId, prestadorId } = req.params;
            const { ServicoValor } = req.body;

            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem vincular serviços a prestadores'
                });
            }

            // Buscar o serviço do estabelecimento
            const servicoEstabelecimento = await prisma.servicoEstabelecimento.findUnique({
                where: { ServicoEstabelecimentoId: parseInt(servicoEstabelecimentoId) },
                include: {
                    estabelecimento: true
                }
            });

            if (!servicoEstabelecimento) {
                return res.status(404).json({ error: 'Serviço do estabelecimento não encontrado' });
            }

            // Verificar se o estabelecimento pertence à empresa
            if (servicoEstabelecimento.estabelecimento.EmpresaId !== req.usuario.usuarioId) {
                return res.status(403).json({
                    error: 'Este serviço não pertence a um estabelecimento da sua empresa'
                });
            }

            // Verificar se o prestador existe e está ATIVO
            const prestador = await prisma.usuario.findFirst({
                where: {
                    UsuarioId: parseInt(prestadorId),
                    UsuarioTipo: 'PRESTADOR',
                    UsuarioStatus: 'ATIVO'
                }
            });

            if (!prestador) {
                return res.status(404).json({ error: 'Prestador não encontrado ou não está ativo' });
            }

            // Verificar se o prestador tem vínculo ATIVO com o estabelecimento
            const vinculo = await prisma.usuarioEstabelecimento.findFirst({
                where: {
                    UsuarioId: parseInt(prestadorId),
                    EstabelecimentoId: servicoEstabelecimento.estabelecimento.EstabelecimentoId,
                    UsuarioEstabelecimentoStatus: 'ATIVO'
                }
            });

            if (!vinculo) {
                return res.status(403).json({
                    error: 'Este prestador não possui vínculo ativo com o estabelecimento'
                });
            }

            if (ServicoValor && ServicoValor > 0) {
            } else {
                return res.status(409).json({
                    error: 'Valor inicial do serviço é obrigatório'
                });
            }

            // Verificar se já existe um vínculo deste serviço com este prestador
            const vinculoExistente = await prisma.servico.findFirst({
                where: {
                    PrestadorId: parseInt(prestadorId),
                    ServicoEstabelecimentoId: parseInt(servicoEstabelecimentoId)
                }
            });

            if (vinculoExistente) {
                if (vinculoExistente.ServicoAtivo) {
                    return res.status(409).json({
                        error: 'Este serviço já está vinculado a este prestador'
                    });
                } else {
                    await prisma.servico.update({
                        where: {
                            ServicoId: vinculoExistente.ServicoId
                        },
                        data: {
                            ServicoAtivo: true,
                            ServicoNome: servicoEstabelecimento.ServicoNome,
                            ServicoDescricao: servicoEstabelecimento.ServicoDescricao,
                            ServicoTempoMedio: servicoEstabelecimento.ServicoTempoMedio,
                        }
                    });

                    vinculoExistente.ServicoAtivo = true;

                    // Criar o preço inicial
                    await prisma.servicoPreco.create({
                        data: {
                            ServicoId: vinculoExistente.ServicoId,
                            EstabelecimentoId: servicoEstabelecimento.estabelecimento.EstabelecimentoId,
                            ServicoValor: parseFloat(ServicoValor)
                        }
                    });

                    res.status(201).json({
                        message: 'Serviço vinculado ao prestador com sucesso',
                        data: vinculoExistente
                    });

                }
            } else {
                // Criar o serviço vinculado ao prestador
                const novoServico = await prisma.servico.create({
                    data: {
                        PrestadorId: parseInt(prestadorId),
                        ServicoEstabelecimentoId: parseInt(servicoEstabelecimentoId),
                        ServicoNome: servicoEstabelecimento.ServicoNome,
                        ServicoDescricao: servicoEstabelecimento.ServicoDescricao,
                        ServicoTempoMedio: servicoEstabelecimento.ServicoTempoMedio,
                        ServicoAtivo: true
                    }
                });

                // Criar o preço inicial
                await prisma.servicoPreco.create({
                    data: {
                        ServicoId: novoServico.ServicoId,
                        EstabelecimentoId: servicoEstabelecimento.estabelecimento.EstabelecimentoId,
                        ServicoValor: parseFloat(ServicoValor)
                    }
                });

                res.status(201).json({
                    message: 'Serviço vinculado ao prestador com sucesso',
                    data: novoServico
                });
            }

        } catch (error) {
            console.error('Erro ao vincular serviço a prestador:', error);
            res.status(500).json({
                error: 'Erro ao vincular serviço a prestador'
            });
        }
    }

    // Listar prestadores disponíveis para vincular a um serviço
    async listarPrestadoresDisponiveisParaServico(req, res) {
        try {
            const { servicoEstabelecimentoId } = req.params;

            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem listar prestadores disponíveis'
                });
            }

            // Buscar o serviço do estabelecimento
            const servico = await prisma.servicoEstabelecimento.findUnique({
                where: { ServicoEstabelecimentoId: parseInt(servicoEstabelecimentoId) },
                include: {
                    estabelecimento: true
                }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            // Verificar se o estabelecimento pertence à empresa
            if (servico.estabelecimento.EmpresaId !== req.usuario.usuarioId) {
                return res.status(403).json({
                    error: 'Este serviço não pertence a um estabelecimento da sua empresa'
                });
            }

            //console.log('Servico | ', servico);

            // Buscar prestadores com vínculo ATIVO no estabelecimento
            const prestadoresComVinculo = await prisma.usuarioEstabelecimento.findMany({
                where: {
                    EstabelecimentoId: servico.estabelecimento.EstabelecimentoId,
                    UsuarioEstabelecimentoStatus: 'ATIVO'
                },
                include: {
                    usuario: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    }
                }
            });

            //console.log('prestadoresComVinculo | ', prestadoresComVinculo);

            // IDs dos prestadores com vínculo
            const prestadoresIds = prestadoresComVinculo.map(v => v.usuario.UsuarioId);

            // Buscar IDs dos prestadores que já têm este serviço vinculado
            const servicosVinculados = await prisma.servico.findMany({
                where: {
                    ServicoEstabelecimentoId: parseInt(servicoEstabelecimentoId),
                    PrestadorId: { in: prestadoresIds },
                    ServicoAtivo: true
                },
                select: { PrestadorId: true }
            });

            const idsVinculados = servicosVinculados.map(s => s.PrestadorId);
            //console.log('idsVinculados | ', idsVinculados);

            // Filtrar apenas prestadores que ainda não têm o serviço vinculado
            const prestadoresDisponiveis = prestadoresComVinculo
                .filter(v => !idsVinculados.includes(v.usuario.UsuarioId))
                .map(v => v.usuario);

            //console.log('prestadoresDisponiveis | ', prestadoresDisponiveis);

            res.status(200).json({
                data: prestadoresDisponiveis
            });

        } catch (error) {
            console.error('Erro ao listar prestadores disponíveis:', error);
            res.status(500).json({
                error: 'Erro ao listar prestadores disponíveis'
            });
        }
    }

    // Listar prestadores vinculados a um serviço
    async listarPrestadoresVinculados(req, res) {
        try {
            const { servicoEstabelecimentoId } = req.params;

            const servicos = await prisma.servico.findMany({
                where: {
                    ServicoEstabelecimentoId: parseInt(servicoEstabelecimentoId),
                    ServicoAtivo: true
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true,
                            UsuarioStatus: true
                        }
                    },
                    precos: {
                        orderBy: {
                            ServicoPrecoDtCriacao: 'desc'
                        },
                        take: 1
                    }
                }
            });

            const resultado = servicos.map(s => ({
                vinculoId: s.ServicoId,
                prestador: s.prestador,
                precoAtual: s.precos && s.precos.length > 0
                    ? parseFloat(s.precos[0].ServicoValor)
                    : null,
                ativo: s.ServicoAtivo
            }));

            res.status(200).json({
                data: resultado
            });

        } catch (error) {
            console.error('Erro ao listar prestadores vinculados:', error);
            res.status(500).json({
                error: 'Erro ao listar prestadores vinculados'
            });
        }
    }

    // Desvincular serviço de um prestador
    async desvincularServicoDePrestador(req, res) {
        try {
            const { servicoId } = req.params;

            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem desvincular serviços'
                });
            }

            // Buscar o serviço vinculado
            const servicoVinculado = await prisma.servico.findUnique({
                where: { ServicoId: parseInt(servicoId) },
                include: {
                    servicoEstabelecimento: {
                        include: {
                            estabelecimento: true
                        }
                    }
                }
            });

            if (!servicoVinculado) {
                return res.status(404).json({ error: 'Vínculo não encontrado' });
            }

            // Verificar se o estabelecimento pertence à empresa
            if (servicoVinculado.servicoEstabelecimento.estabelecimento.EmpresaId !== req.usuario.usuarioId) {
                return res.status(403).json({
                    error: 'Você só pode desvincular serviços dos seus estabelecimentos'
                });
            }

            // Verificar se existem agendamentos ativos
            const agendamentosAtivos = await prisma.servicoAgendamento.count({
                where: {
                    ServicoId: parseInt(servicoId),
                    agendamento: {
                        AgendamentoStatus: {
                            in: ['PENDENTE', 'CONFIRMADO', 'EM_ANDAMENTO']
                        }
                    }
                }
            });

            if (agendamentosAtivos > 0) {
                return res.status(400).json({
                    error: 'Não é possível desvincular um serviço com agendamentos ativos'
                });
            }

            // Desativando os seviço  vinculado
            await prisma.servico.update({
                where: { ServicoId: parseInt(servicoId) },
                data: {
                    ServicoAtivo: false
                }
            });

            res.status(200).json({
                message: 'Serviço desvinculado do prestador com sucesso'
            });

        } catch (error) {
            console.error('Erro ao desvincular serviço:', error);
            res.status(500).json({
                error: 'Erro ao desvincular serviço'
            });
        }
    }

    // Listar serviços de um prestador vinculados a um estabelecimento
    async listarServicosPrestadorPorEstabelecimento(req, res) {
        try {
            const { prestadorId, estabelecimentoId } = req.params;

            // Verificar se o prestador existe
            const prestador = await prisma.usuario.findUnique({
                where: { UsuarioId: parseInt(prestadorId) }
            });

            if (!prestador || prestador.UsuarioTipo !== 'PRESTADOR') {
                return res.status(404).json({ error: 'Prestador não encontrado' });
            }

            // Buscar serviços do prestador vinculados ao estabelecimento
            const servicos = await prisma.servico.findMany({
                where: {
                    PrestadorId: parseInt(prestadorId),
                    ServicoAtivo: true,
                    servicoEstabelecimento: {
                        EstabelecimentoId: parseInt(estabelecimentoId)
                    }
                },
                include: {
                    servicoEstabelecimento: {
                        select: {
                            ServicoEstabelecimentoId: true,
                            ServicoNome: true
                        }
                    },
                    precos: {
                        orderBy: {
                            ServicoPrecoDtCriacao: 'desc'
                        },
                        take: 1
                    }
                },
                orderBy: {
                    ServicoNome: 'asc'
                }
            });

            const servicosFormatados = servicos.map(servico => ({
                ServicoId: servico.ServicoId,
                ServicoNome: servico.ServicoNome,
                ServicoDescricao: servico.ServicoDescricao,
                ServicoTempoMedio: servico.ServicoTempoMedio,
                precoAtual: servico.precos && servico.precos.length > 0
                    ? parseFloat(servico.precos[0].ServicoValor)
                    : null,
                servicoEstabelecimento: servico.servicoEstabelecimento
            }));

            res.status(200).json({
                success: true,
                data: servicosFormatados
            });

        } catch (error) {
            console.error('Erro ao listar serviços do prestador por estabelecimento:', error);
            res.status(500).json({ error: 'Erro ao listar serviços do prestador por estabelecimento' });
        }
    }

}

module.exports = new ServicoEstabelecimentoController();