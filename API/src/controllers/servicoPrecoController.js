// src/controllers/servicoPrecoController.js
const prisma = require('../prisma.js');

class ServicoPrecoController {

    // Adicionar novo preço para um serviço (prestador dono OU empresa dona do estabelecimento)
    async adicionarPreco(req, res) {
        try {
            const { servicoId } = req.params;
            const { ServicoValor } = req.body;

            // Validações
            if (!servicoId) {
                return res.status(400).json({ error: 'ID do serviço é obrigatório' });
            }

            if (!ServicoValor || ServicoValor <= 0) {
                return res.status(400).json({ error: 'Valor do serviço é obrigatório e deve ser maior que zero' });
            }

            // Buscar o serviço com suas relações
            const servico = await prisma.servico.findUnique({
                where: { ServicoId: parseInt(servicoId) },
                include: {
                    prestador: true,
                    servicoEstabelecimento: {
                        include: {
                            estabelecimento: true
                        }
                    }
                }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            // Verificar permissão:
            // - Se for serviço de prestador (sem estabelecimento): apenas o prestador dono
            // - Se for serviço de estabelecimento: prestador dono OU empresa dona do estabelecimento
            const isPrestadorDono = servico.PrestadorId === req.usuario.usuarioId;
            const isEmpresaDona = servico.servicoEstabelecimento?.estabelecimento?.EmpresaId === req.usuario.usuarioId;

            if (!isPrestadorDono && !isEmpresaDona) {
                return res.status(403).json({
                    error: 'Você não tem permissão para adicionar preço a este serviço'
                });
            }

            // Criar novo registro de preço
            const novoPreco = await prisma.servicoPreco.create({
                data: {
                    ServicoId: parseInt(servicoId),
                    EstabelecimentoId: servico.servicoEstabelecimento?.estabelecimento?.EstabelecimentoId || null,
                    ServicoValor: ServicoValor
                },
                include: {
                    servico: {
                        select: {
                            ServicoId: true,
                            ServicoNome: true
                        }
                    }
                }
            });

            // Formatar resposta
            const respostaFormatada = {
                ...novoPreco,
                ServicoValor: parseFloat(novoPreco.ServicoValor)
            };

            res.status(201).json({
                message: 'Preço adicionado com sucesso',
                data: respostaFormatada
            });

        } catch (error) {
            console.error('Erro ao adicionar preço:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Listar histórico de preços de um serviço (qualquer usuário logado)
    async listarPrecosPorServico(req, res) {
        try {
            const { servicoId } = req.params;

            if (!servicoId) {
                return res.status(400).json({ error: 'ID do serviço é obrigatório' });
            }

            // Verificar se o serviço existe
            const servico = await prisma.servico.findUnique({
                where: {
                    ServicoId: parseInt(servicoId)
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true
                        }
                    }
                }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            // Buscar todos os preços do serviço em ordem decrescente (mais recentes primeiro)
            const precos = await prisma.servicoPreco.findMany({
                where: {
                    ServicoId: parseInt(servicoId)
                },
                orderBy: {
                    ServicoPrecoDtCriacao: 'desc'
                },
                include: {
                    servico: {
                        select: {
                            ServicoNome: true,
                            ServicoTempoMedio: true
                        }
                    }
                }
            });

            // Formatar resposta (converter Decimal para número)
            const precosFormatados = precos.map(preco => ({
                ...preco,
                ServicoValor: parseFloat(preco.ServicoValor)
            }));

            // Calcular algumas estatísticas básicas
            const estatisticas = {
                totalPrecos: precos.length,
                precoAtual: precos.length > 0 ? parseFloat(precos[0].ServicoValor) : null,
                precoMedio: precos.length > 0
                    ? parseFloat((precos.reduce((acc, p) => acc + parseFloat(p.ServicoValor), 0) / precos.length).toFixed(2))
                    : null,
                menorPreco: precos.length > 0
                    ? parseFloat(Math.min(...precos.map(p => parseFloat(p.ServicoValor))).toFixed(2))
                    : null,
                maiorPreco: precos.length > 0
                    ? parseFloat(Math.max(...precos.map(p => parseFloat(p.ServicoValor))).toFixed(2))
                    : null,
                primeiroPreco: precos.length > 0
                    ? {
                        valor: parseFloat(precos[precos.length - 1].ServicoValor),
                        data: precos[precos.length - 1].ServicoPrecoDtCriacao
                    }
                    : null
            };

            res.status(200).json({
                data: precosFormatados,
                servico: {
                    id: servico.ServicoId,
                    nome: servico.ServicoNome,
                    tempoMedio: servico.ServicoTempoMedio,
                    prestador: servico.prestador
                },
                estatisticas: estatisticas
            });

        } catch (error) {
            console.error('Erro ao listar preços:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Buscar preço específico por ID (qualquer usuário logado)
    async buscarPrecoId(req, res) {
        try {
            const { precoId } = req.params;

            if (!precoId) {
                return res.status(400).json({ error: 'ID do preço é obrigatório' });
            }

            const preco = await prisma.servicoPreco.findUnique({
                where: {
                    ServicoPrecoId: parseInt(precoId)
                },
                include: {
                    servico: {
                        include: {
                            prestador: {
                                select: {
                                    UsuarioId: true,
                                    UsuarioNome: true,
                                    UsuarioEmail: true
                                }
                            }
                        }
                    }
                }
            });

            if (!preco) {
                return res.status(404).json({ error: 'Preço não encontrado' });
            }

            // Formatar resposta
            const respostaFormatada = {
                ...preco,
                ServicoValor: parseFloat(preco.ServicoValor)
            };

            res.status(200).json({ data: respostaFormatada });

        } catch (error) {
            console.error('Erro ao buscar preço:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Buscar preço atual de um serviço (qualquer usuário logado)
    async buscarPrecoAtual(req, res) {
        try {
            const { servicoId } = req.params;

            if (!servicoId) {
                return res.status(400).json({ error: 'ID do serviço é obrigatório' });
            }

            // Buscar o preço mais recente do serviço
            const precoAtual = await prisma.servicoPreco.findFirst({
                where: {
                    ServicoId: parseInt(servicoId)
                },
                orderBy: {
                    ServicoPrecoDtCriacao: 'desc'
                },
                include: {
                    servico: {
                        select: {
                            ServicoNome: true,
                            ServicoTempoMedio: true,
                            ServicoAtivo: true,
                            prestador: {
                                select: {
                                    UsuarioId: true,
                                    UsuarioNome: true
                                }
                            }
                        }
                    }
                }
            });

            if (!precoAtual) {
                return res.status(404).json({ error: 'Nenhum preço encontrado para este serviço' });
            }

            // Buscar também o preço anterior para comparação
            const precoAnterior = await prisma.servicoPreco.findFirst({
                where: {
                    ServicoId: parseInt(servicoId),
                    ServicoPrecoId: {
                        not: precoAtual.ServicoPrecoId
                    }
                },
                orderBy: {
                    ServicoPrecoDtCriacao: 'desc'
                }
            });

            // Formatar resposta
            const respostaFormatada = {
                precoAtual: {
                    id: precoAtual.ServicoPrecoId,
                    valor: parseFloat(precoAtual.ServicoValor),
                    dataCriacao: precoAtual.ServicoPrecoDtCriacao
                },
                servico: {
                    id: precoAtual.servico.ServicoId,
                    nome: precoAtual.servico.ServicoNome,
                    tempoMedio: precoAtual.servico.ServicoTempoMedio,
                    ativo: precoAtual.servico.ServicoAtivo,
                    prestador: precoAtual.servico.prestador
                },
                precoAnterior: precoAnterior ? {
                    id: precoAnterior.ServicoPrecoId,
                    valor: parseFloat(precoAnterior.ServicoValor),
                    dataCriacao: precoAnterior.ServicoPrecoDtCriacao,
                    diferenca: parseFloat((parseFloat(precoAtual.ServicoValor) - parseFloat(precoAnterior.ServicoValor)).toFixed(2)),
                    percentual: ((parseFloat(precoAtual.ServicoValor) - parseFloat(precoAnterior.ServicoValor)) / parseFloat(precoAnterior.ServicoValor) * 100).toFixed(2) + '%'
                } : null
            };

            res.status(200).json({ data: respostaFormatada });

        } catch (error) {
            console.error('Erro ao buscar preço atual:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Atualizar preço de um serviço para todos os prestadores vinculados (apenas EMPRESA dona do estabelecimento)
    async atualizarPrecoServicoEstabelecimento(req, res) {
        try {
            const { servicoEstabelecimentoId } = req.params;
            const { ServicoValor } = req.body;

            // Validações
            if (!servicoEstabelecimentoId) {
                return res.status(400).json({ error: 'ID do serviço do estabelecimento é obrigatório' });
            }

            if (!ServicoValor || ServicoValor <= 0) {
                return res.status(400).json({ error: 'Valor do serviço é obrigatório e deve ser maior que zero' });
            }

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem atualizar preços de serviços do estabelecimento'
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

            // Verificar se o estabelecimento pertence à empresa logada
            if (servicoEstabelecimento.estabelecimento.EmpresaId !== req.usuario.usuarioId) {
                return res.status(403).json({
                    error: 'Você só pode atualizar preços de serviços dos seus estabelecimentos'
                });
            }

            // Buscar todos os serviços vinculados a este serviço do estabelecimento
            const servicosVinculados = await prisma.servico.findMany({
                where: {
                    ServicoEstabelecimentoId: parseInt(servicoEstabelecimentoId),
                    ServicoAtivo: true
                },
                select: {
                    ServicoId: true
                }
            });

            if (servicosVinculados.length === 0) {
                return res.status(404).json({
                    error: 'Não há prestadores vinculados a este serviço'
                });
            }

            // Criar novos registros de preço para cada serviço vinculado em transação
            const resultados = await prisma.$transaction(
                servicosVinculados.map(servico =>
                    prisma.servicoPreco.create({
                        data: {
                            ServicoId: servico.ServicoId,
                            EstabelecimentoId: servicoEstabelecimento.estabelecimento.EstabelecimentoId,
                            ServicoValor: ServicoValor
                        }
                    })
                )
            );

            // Buscar os serviços atualizados com os novos preços
            const servicosAtualizados = await prisma.servico.findMany({
                where: {
                    ServicoEstabelecimentoId: parseInt(servicoEstabelecimentoId),
                    ServicoAtivo: true
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true
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
            const respostaFormatada = servicosAtualizados.map(s => ({
                vinculoId: s.ServicoId,
                prestador: s.prestador,
                precoAtual: s.precos && s.precos.length > 0 ? parseFloat(s.precos[0].ServicoValor) : null
            }));

            res.status(200).json({
                success: true,
                message: `Preço atualizado para ${resultados.length} prestador(es) com sucesso`,
                data: {
                    servicoEstabelecimentoId: parseInt(servicoEstabelecimentoId),
                    servicoNome: servicoEstabelecimento.ServicoNome,
                    novoPreco: parseFloat(ServicoValor),
                    prestadoresAtualizados: respostaFormatada
                }
            });

        } catch (error) {
            console.error('Erro ao atualizar preço do serviço do estabelecimento:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

}

module.exports = new ServicoPrecoController();