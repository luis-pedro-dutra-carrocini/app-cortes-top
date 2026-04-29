// src/controllers/servicoController.js
const prisma = require('../prisma.js');

class ServicoController {

    // Cadastrar serviço (apenas PRESTADOR)
    async cadastrarServico(req, res) {
        try {
            const {
                ServicoNome,
                ServicoDescricao,
                ServicoTempoMedio,
                ServicoAtivo = true
            } = req.body;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem cadastrar serviços'
                });
            }

            // Validações
            if (!ServicoNome || ServicoNome.trim() === '') {
                return res.status(400).json({ error: 'Nome do serviço é obrigatório' });
            }

            if (!ServicoTempoMedio || ServicoTempoMedio <= 0) {
                return res.status(400).json({ error: 'Tempo médio é obrigatório e deve ser maior que zero' });
            }

            // Criar serviço
            const servico = await prisma.servico.create({
                data: {
                    PrestadorId: req.usuario.usuarioId,
                    ServicoNome: ServicoNome.trim(),
                    ServicoDescricao: ServicoDescricao ? ServicoDescricao.trim() : null,
                    ServicoTempoMedio: parseInt(ServicoTempoMedio),
                    ServicoAtivo: ServicoAtivo
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    }
                }
            });

            res.status(201).json({
                message: 'Serviço cadastrado com sucesso',
                data: servico
            });

        } catch (error) {
            console.error('Erro ao cadastrar serviço:', error);
            res.status(500).json({
                error: 'Erro ao cadastrar serviço'
            });
        }
    }

    // Listar todos os serviços de um prestador (qualquer usuário logado)
    async listarServicosPorPrestador(req, res) {
        try {
            const { prestadorId } = req.params;

            // Verificar se o prestador existe
            const prestador = await prisma.usuario.findUnique({
                where: { UsuarioId: parseInt(prestadorId) }
            });

            if (!prestador) {
                return res.status(404).json({ error: 'Prestador não encontrado' });
            }

            if (prestador.UsuarioTipo !== 'PRESTADOR') {
                return res.status(400).json({ error: 'O usuário informado não é um prestador' });
            }

            // Buscar serviços do prestador
            const servicos = await prisma.servico.findMany({
                where: {
                    PrestadorId: parseInt(prestadorId),
                    ServicoAtivo: true,
                    ServicoEstabelecimentoId: null,
                    precos: {
                        some: {} // Garante que existe pelo menos um preço
                    }
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
                    precos: {
                        orderBy: {
                            ServicoPrecoDtCriacao: 'desc' // Campo correto: data de criação
                        },
                        take: 1 // Pega apenas o preço mais recente
                    }
                },
                orderBy: {
                    ServicoNome: 'asc'
                }
            });

            // Formatar a resposta para incluir o preço atual de forma mais acessível
            const servicosFormatados = servicos.map(servico => ({
                ServicoId: servico.ServicoId,
                PrestadorId: servico.PrestadorId,
                ServicoNome: servico.ServicoNome,
                ServicoDescricao: servico.ServicoDescricao,
                ServicoTempoMedio: servico.ServicoTempoMedio,
                ServicoAtivo: servico.ServicoAtivo,
                prestador: servico.prestador,
                precoAtual: servico.precos && servico.precos.length > 0
                    ? parseFloat(servico.precos[0].ServicoValor)
                    : null,
                ultimoPreco: servico.precos && servico.precos.length > 0
                    ? {
                        valor: parseFloat(servico.precos[0].ServicoValor),
                        dataCriacao: servico.precos[0].ServicoPrecoDtCriacao
                    }
                    : null
            }));

            res.status(200).json({
                data: servicosFormatados,
                prestador: {
                    id: prestador.UsuarioId,
                    nome: prestador.UsuarioNome
                }
            });

        } catch (error) {
            console.error('Erro ao listar serviços:', error);
            res.status(500).json({
                error: 'Erro ao listar serviços'
            });
        }
    }

    // Lista todos os serviços de um prestador, incluindo inativos (somente o dono dos serviços)
    async listarTodosServicosPorPrestador(req, res) {
        try {
            const { prestadorId } = req.params;

            // Verificar se o prestador existe
            const prestador = await prisma.usuario.findUnique({
                where: { UsuarioId: parseInt(prestadorId) }
            });

            if (!prestador) {
                return res.status(404).json({ error: 'Prestador não encontrado' });
            }

            if (prestador.UsuarioTipo !== 'PRESTADOR') {
                return res.status(400).json({ error: 'O usuário informado não é um prestador' });
            }

            if (prestador.UsuarioId !== req.usuario.usuarioId) {
                return res.status(403).json({
                    error: 'Você só pode acessar todos os seus próprios serviços'
                });
            }

            // Buscar serviços do prestador que não tem relação com estabelecimentos
            const servicos = await prisma.servico.findMany({
                where: {
                    PrestadorId: parseInt(prestadorId),
                    ServicoEstabelecimentoId: null // Garante que são serviços do prestador, não vinculados a estabelecimentos
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
                    precos: {
                        orderBy: {
                            ServicoPrecoDtCriacao: 'desc' // Campo correto: data de criação
                        },
                        take: 1 // Pega apenas o preço mais recente
                    }
                },
                orderBy: {
                    ServicoNome: 'asc'
                }
            });

            // Formatar a resposta para incluir o preço atual de forma mais acessível
            const servicosFormatados = servicos.map(servico => ({
                ServicoId: servico.ServicoId,
                PrestadorId: servico.PrestadorId,
                ServicoNome: servico.ServicoNome,
                ServicoDescricao: servico.ServicoDescricao,
                ServicoTempoMedio: servico.ServicoTempoMedio,
                ServicoAtivo: servico.ServicoAtivo,
                prestador: servico.prestador,
                precoAtual: servico.precos && servico.precos.length > 0
                    ? parseFloat(servico.precos[0].ServicoValor)
                    : null,
                ultimoPreco: servico.precos && servico.precos.length > 0
                    ? {
                        valor: parseFloat(servico.precos[0].ServicoValor),
                        dataCriacao: servico.precos[0].ServicoPrecoDtCriacao
                    }
                    : null
            }));

            res.status(200).json({
                data: servicosFormatados,
                prestador: {
                    id: prestador.UsuarioId,
                    nome: prestador.UsuarioNome
                }
            });

        } catch (error) {
            console.error('Erro ao listar serviços:', error);
            res.status(500).json({
                error: 'Erro ao listar serviços'
            });
        }
    }

    // Buscar serviço por ID (qualquer usuário logado)
    async buscarServicoId(req, res) {
        try {
            const { servicoId } = req.params;

            const servico = await prisma.servico.findUnique({
                where: {
                    ServicoId: parseInt(servicoId)
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
                    precos: {
                        orderBy: {
                            ServicoPrecoDtCriacao: 'desc' // Campo correto: data de criação
                        }
                    }
                }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            // Formatar a resposta
            const servicoFormatado = {
                ServicoId: servico.ServicoId,
                PrestadorId: servico.PrestadorId,
                ServicoNome: servico.ServicoNome,
                ServicoDescricao: servico.ServicoDescricao,
                ServicoTempoMedio: servico.ServicoTempoMedio,
                ServicoAtivo: servico.ServicoAtivo,
                prestador: servico.prestador,
                precos: servico.precos.map(preco => ({
                    ...preco,
                    ServicoValor: parseFloat(preco.ServicoValor)
                })),
                precoAtual: servico.precos && servico.precos.length > 0
                    ? parseFloat(servico.precos[0].ServicoValor)
                    : null
            };

            res.status(200).json({ data: servicoFormatado });

        } catch (error) {
            console.error('Erro ao buscar serviço:', error);
            res.status(500).json({
                error: 'Erro ao buscar serviço'
            });
        }
    }

    // Atualizar serviço (apenas o PRESTADOR dono do serviço)
    async atualizarServico(req, res) {
        try {
            const servicoId = parseInt(req.params.id);
            const {
                ServicoNome,
                ServicoDescricao,
                ServicoTempoMedio,
                ServicoAtivo
            } = req.body;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem atualizar serviços'
                });
            }

            // Buscar o serviço
            const servico = await prisma.servico.findUnique({
                where: { ServicoId: servicoId }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            // Verificar se o serviço pertence ao prestador logado e não tem relação com estabelecimento
            if (servico.PrestadorId !== req.usuario.usuarioId && servico.ServicoEstabelecimentoId === null) {
                return res.status(403).json({
                    error: 'Você só pode atualizar seus próprios serviços'
                });
            }

            // Validações básicas
            if (ServicoTempoMedio && ServicoTempoMedio <= 0) {
                return res.status(400).json({ error: 'Tempo médio deve ser maior que zero' });
            }

            // Atualizar serviço
            const servicoAtualizado = await prisma.servico.update({
                where: {
                    ServicoId: servicoId
                },
                data: {
                    ServicoNome: ServicoNome ? ServicoNome.trim() : servico.ServicoNome,
                    ServicoDescricao: ServicoDescricao !== undefined ? (ServicoDescricao ? ServicoDescricao.trim() : null) : servico.ServicoDescricao,
                    ServicoTempoMedio: ServicoTempoMedio ? parseInt(ServicoTempoMedio) : servico.ServicoTempoMedio,
                    ServicoAtivo: ServicoAtivo !== undefined ? ServicoAtivo : servico.ServicoAtivo
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
                    precos: {
                        orderBy: {
                            ServicoPrecoDtCriacao: 'desc'
                        },
                        take: 1
                    }
                }
            });

            // Formatar resposta
            const respostaFormatada = {
                ...servicoAtualizado,
                precoAtual: servicoAtualizado.precos && servicoAtualizado.precos.length > 0
                    ? parseFloat(servicoAtualizado.precos[0].ServicoValor)
                    : null
            };

            res.status(200).json({
                message: 'Serviço atualizado com sucesso',
                data: respostaFormatada
            });

        } catch (error) {
            console.error('Erro ao atualizar serviço:', error);
            res.status(500).json({
                error: 'Erro ao atualizar serviço'
            });
        }
    }

    // Excluir serviço (apenas o PRESTADOR dono do serviço)
    async excluirServico(req, res) {
        try {
            const servicoId = parseInt(req.params.servicoId);

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem excluir serviços'
                });
            }

            // Buscar o serviço
            const servico = await prisma.servico.findUnique({
                where: { ServicoId: servicoId }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            // Verificar se o serviço pertence ao prestador logado e não tem relação com estabelecimento
            if (servico.PrestadorId !== req.usuario.usuarioId && servico.ServicoEstabelecimentoId === null) {
                return res.status(403).json({
                    error: 'Você só pode excluir seus próprios serviços'
                });
            }

            // CORREÇÃO: Verificar se existem agendamentos relacionados ao serviço
            const agendamentosRelacionados = await prisma.servicoAgendamento.findMany({
                where: {
                    ServicoId: servicoId
                },
                include: {
                    agendamento: {
                        select: {
                            AgendamentoStatus: true
                        }
                    }
                }
            });

            if (agendamentosRelacionados.length > 0) {
                return res.status(400).json({
                    error: 'Não é possível excluir um serviço que possui agendamentos vinculados'
                });
            }

            // Excluir serviço e seus preços relacionados em uma transação
            await prisma.$transaction([
                prisma.servicoPreco.deleteMany({
                    where: { ServicoId: servicoId }
                }),
                prisma.servico.delete({
                    where: { ServicoId: servicoId }
                })
            ]);

            res.status(200).json({
                message: 'Serviço excluído com sucesso'
            });

        } catch (error) {
            console.error('Erro ao excluir serviço:', error);
            res.status(500).json({ error: 'Erro ao excluir serviço' });
        }
    }

    // Ativar/Desativar serviço (apenas o PRESTADOR dono do serviço)
    async alternarStatusServico(req, res) {
        try {
            const servicoId = parseInt(req.params.servicoId);
            const { ativo } = req.body;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem alterar o status do serviço'
                });
            }

            // Validar parâmetro
            if (ativo === undefined || typeof ativo !== 'boolean') {
                return res.status(400).json({
                    error: 'O campo "ativo" é obrigatório e deve ser true ou false'
                });
            }

            // Buscar o serviço
            const servico = await prisma.servico.findUnique({
                where: { ServicoId: servicoId }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            // Verificar se o serviço pertence ao prestador logado e não tem relação com estabelecimento
            if (servico.PrestadorId !== req.usuario.usuarioId && servico.ServicoEstabelecimentoId === null) {
                return res.status(403).json({
                    error: 'Você só pode alterar o status dos seus próprios serviços'
                });
            }

            // CORREÇÃO: Verificar se existem agendamentos ativos relacionados ao serviço
            const agendamentosRelacionados = await prisma.servicoAgendamento.findMany({
                where: {
                    ServicoId: servicoId
                },
                include: {
                    agendamento: {
                        select: {
                            AgendamentoStatus: true
                        }
                    }
                }
            });

            // Filtrar apenas agendamentos não cancelados
            const agendamentosAtivos = agendamentosRelacionados.filter(sa =>
                sa.agendamento.AgendamentoStatus !== 'CANCELADO' &&
                sa.agendamento.AgendamentoStatus !== 'CONCLUIDO'
            );

            // Se estiver tentando desativar e existem agendamentos ativos
            if (!ativo && agendamentosAtivos.length > 0) {
                return res.status(400).json({
                    error: 'Não é possível desativar um serviço que possui agendamentos pendentes ou confirmados'
                });
            }

            // Atualizar status
            const servicoAtualizado = await prisma.servico.update({
                where: {
                    ServicoId: servicoId
                },
                data: {
                    ServicoAtivo: ativo
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    }
                }
            });

            res.status(200).json({
                message: `Serviço ${ativo ? 'ativado' : 'desativado'} com sucesso`,
                data: servicoAtualizado
            });

        } catch (error) {
            console.error('Erro ao alterar status do serviço:', error);
            res.status(500).json({ error: 'Erro ao alterar status do serviço' });
        }
    }
}

module.exports = new ServicoController();