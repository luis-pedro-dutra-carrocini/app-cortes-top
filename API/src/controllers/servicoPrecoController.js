// src/controllers/servicoPrecoController.js
const prisma = require('../prisma.js');

class ServicoPrecoController {

    // Adicionar novo preço para um serviço (apenas PRESTADOR dono do serviço)
    async adicionarPreco(req, res) {
        try {
            const { servicoId } = req.params;
            const { ServicoValor } = req.body;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({ 
                    error: 'Apenas prestadores podem adicionar preços' 
                });
            }

            // Validações
            if (!servicoId) {
                return res.status(400).json({ error: 'ID do serviço é obrigatório' });
            }

            if (!ServicoValor && ServicoValor !== 0) {
                return res.status(400).json({ error: 'Valor do serviço é obrigatório' });
            }

            if (ServicoValor <= 0) {
                return res.status(400).json({ error: 'Valor do serviço deve ser maior que zero' });
            }

            // Buscar o serviço para verificar se existe e se pertence ao prestador
            const servico = await prisma.servico.findUnique({
                where: { 
                    ServicoId: parseInt(servicoId) 
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioTipo: true
                        }
                    }
                }
            });

            if (!servico) {
                return res.status(404).json({ error: 'Serviço não encontrado' });
            }

            // Verificar se o serviço pertence ao prestador logado e não tem relação com estabelecimento
            if (servico.PrestadorId !== req.usuario.usuarioId && servico.ServicoEstabelecimentoId === null) {
                return res.status(403).json({ 
                    error: 'Você só pode adicionar preços aos seus próprios serviços' 
                });
            }

            // Verificar se o serviço está ativo
            if (!servico.ServicoAtivo) {
                return res.status(400).json({ 
                    error: 'Não é possível adicionar preço a um serviço inativo' 
                });
            }

            // Criar novo registro de preço
            const novoPreco = await prisma.servicoPreco.create({
                data: {
                    ServicoId: parseInt(servicoId),
                    ServicoValor: ServicoValor
                },
                include: {
                    servico: {
                        select: {
                            ServicoId: true,
                            ServicoNome: true,
                            ServicoTempoMedio: true,
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

            // Formatar resposta (converter Decimal para número)
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
}

module.exports = new ServicoPrecoController();