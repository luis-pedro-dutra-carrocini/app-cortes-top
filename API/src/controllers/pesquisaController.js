const prisma = require('../prisma.js');

class PesquisaController {

    // Métodos auxiliares
    async _buscarPrestadores(termo) {
        const prestadores = await prisma.usuario.findMany({
            where: {
                UsuarioTipo: 'PRESTADOR',
                UsuarioStatus: 'ATIVO',
                OR: [
                    { UsuarioNome: { contains: termo, mode: 'insensitive' } },
                    { UsuarioTelefone: { contains: termo } }
                ]
            },
            select: {
                UsuarioId: true,
                UsuarioNome: true,
                UsuarioTelefone: true
            },
            take: 30
        });

        return prestadores.map(p => ({
            id: p.UsuarioId,
            nome: p.UsuarioNome,
            telefone: p.UsuarioTelefone,
            tipo: 'PRESTADOR',
            cidade: p.endereco?.EnderecoCidade,
            estado: p.endereco?.EnderecoEstado
        }));
    }

    async _buscarEmpresas(termo) {
        const empresas = await prisma.empresa.findMany({
            where: {
                EmpresaStatus: 'ATIVA',
                OR: [
                    { EmpresaNome: { contains: termo, mode: 'insensitive' } },
                    { EmpresaTelefone: { contains: termo } }
                ]
            },
            select: {
                EmpresaId: true,
                EmpresaNome: true,
                EmpresaTelefone: true,
                EmpresaDescricao: true
            },
            take: 30
        });

        return empresas.map(e => ({
            id: e.EmpresaId,
            nome: e.EmpresaNome,
            telefone: e.EmpresaTelefone,
            descricao: e.EmpresaDescricao,
            tipo: 'EMPRESA'
        }));
    }

    async _buscarEstabelecimentos(termo) {
        const estabelecimentos = await prisma.estabelecimento.findMany({
            where: {
                EstabelecimentoStatus: 'ATIVO',
                OR: [
                    { EstabelecimentoNome: { contains: termo, mode: 'insensitive' } },
                    { EstabelecimentoTelefone: { contains: termo } }
                ]
            },
            include: {
                empresa: {
                    select: {
                        EmpresaId: true,
                        EmpresaNome: true
                    }
                },
            },
            take: 30
        });

        return estabelecimentos.map(e => ({
            id: e.EstabelecimentoId,
            nome: e.EstabelecimentoNome,
            telefone: e.EstabelecimentoTelefone,
            tipo: 'ESTABELECIMENTO',
            empresa: e.empresa ? {
                id: e.empresa.EmpresaId,
                nome: e.empresa.EmpresaNome
            } : null
        }));
    }

    // Pesquisar prestadores ativos
    async pesquisarPrestadores(req, res) {
        try {
            const { termo } = req.query;

            if (!termo || termo.trim() === '') {
                return res.status(400).json({ error: 'Termo de busca é obrigatório' });
            }

            const prestadores = await prisma.usuario.findMany({
                where: {
                    UsuarioTipo: 'PRESTADOR',
                    UsuarioStatus: 'ATIVO',
                    OR: [
                        { UsuarioNome: { contains: termo, mode: 'insensitive' } },
                        { UsuarioEmail: { contains: termo, mode: 'insensitive' } },
                        { UsuarioTelefone: { contains: termo } }
                    ]
                },
                select: {
                    UsuarioId: true,
                    UsuarioNome: true,
                    UsuarioTelefone: true,
                    UsuarioEnderecoId: true
                },
                orderBy: {
                    UsuarioNome: 'asc'
                },
                take: 50
            });

            const prestadoresComEndereco = await Promise.all(
                prestadores.map(async (p) => {
                    let endercoCompleto = null;
                    if (p.UsuarioEnderecoId) {
                        const endereco = await prisma.endereco.findFirst({
                            where: {
                                UsuEstId: p.UsuarioId,
                                TipoRelacao: 'USUARIO'
                            },
                            select: {
                                EnderecoCidade: true,
                                EnderecoEstado: true,
                                EnderecoBairro: true,
                                EnderecoNumero: true,
                                EnderecoRua: true
                            }
                        });
                        if (endereco) {
                            endercoCompleto = endereco.EnderecoRua + ', N° ' + endereco.EnderecoNumero + ', ' + endereco.EnderecoBairro + '. ' + endereco.EnderecoCidade + ' - ' + endereco.EnderecoEstado;
                        }
                    }
                    return {
                        id: p.UsuarioId,
                        nome: p.UsuarioNome,
                        telefone: p.UsuarioTelefone,
                        tipo: 'PRESTADOR',
                        endercoCompleto
                    };
                })
            );

            res.status(200).json({
                success: true,
                data: prestadoresComEndereco
            });

        } catch (error) {
            console.error('Erro ao pesquisar prestadores:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // Pesquisar empresas ativas
    async pesquisarEmpresas(req, res) {
        try {
            const { termo } = req.query;

            if (!termo || termo.trim() === '') {
                return res.status(400).json({ error: 'Termo de busca é obrigatório' });
            }

            const empresas = await prisma.empresa.findMany({
                where: {
                    EmpresaStatus: 'ATIVA',
                    OR: [
                        { EmpresaNome: { contains: termo, mode: 'insensitive' } },
                        { EmpresaEmail: { contains: termo, mode: 'insensitive' } },
                        { EmpresaTelefone: { contains: termo } },
                        { EmpresaCNPJ: { contains: termo } }
                    ]
                },
                select: {
                    EmpresaId: true,
                    EmpresaNome: true,
                    EmpresaTelefone: true,
                    EmpresaEmail: true,
                    EmpresaCNPJ: true,
                    EmpresaDescricao: true
                },
                orderBy: {
                    EmpresaNome: 'asc'
                },
                take: 50
            });

            const empresasFormatadas = empresas.map(e => ({
                id: e.EmpresaId,
                nome: e.EmpresaNome,
                telefone: e.EmpresaTelefone,
                email: e.EmpresaEmail,
                cnpj: e.EmpresaCNPJ,
                descricao: e.EmpresaDescricao,
                tipo: 'EMPRESA'
            }));

            res.status(200).json({
                success: true,
                data: empresasFormatadas
            });

        } catch (error) {
            console.error('Erro ao pesquisar empresas:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // Pesquisar estabelecimentos ativos
    async pesquisarEstabelecimentos(req, res) {
        try {
            const { termo } = req.query;

            if (!termo || termo.trim() === '') {
                return res.status(400).json({ error: 'Termo de busca é obrigatório' });
            }

            const estabelecimentos = await prisma.estabelecimento.findMany({
                where: {
                    EstabelecimentoStatus: 'ATIVO',
                    OR: [
                        { EstabelecimentoNome: { contains: termo, mode: 'insensitive' } },
                        { EstabelecimentoTelefone: { contains: termo } }
                    ]
                },
                include: {
                    empresa: {
                        select: {
                            EmpresaId: true,
                            EmpresaNome: true
                        }
                    },
                },
                orderBy: {
                    EstabelecimentoNome: 'asc'
                },
                take: 50
            });

            const estabelecimentosComEndereco = await Promise.all(
                estabelecimentos.map(async (e) => {
                    let enderecoInfo = null;
                    if (e.EstabelecimentoEndereco) {
                        const endereco = await prisma.endereco.findFirst({
                            where: {
                                UsuEstId: e.EstabelecimentoId,
                                TipoRelacao: 'ESTABELECIMENTO'
                            },
                            select: {
                                EnderecoCidade: true,
                                EnderecoEstado: true,
                                EnderecoBairro: true,
                                EnderecoRua: true
                            }
                        });
                        if (endereco) {
                            enderecoInfo = {
                                cidade: endereco.EnderecoCidade,
                                estado: endereco.EnderecoEstado,
                                bairro: endereco.EnderecoBairro,
                                rua: endereco.EnderecoRua
                            };
                        }
                    }
                    return {
                        id: e.EstabelecimentoId,
                        nome: e.EstabelecimentoNome,
                        telefone: e.EstabelecimentoTelefone,
                        tipo: 'ESTABELECIMENTO'
                    };
                })
            );

            res.status(200).json({
                success: true,
                data: estabelecimentosComEndereco
            });

        } catch (error) {
            console.error('Erro ao pesquisar estabelecimentos:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // Pesquisa combinada (prestadores, empresas e estabelecimentos)
    async pesquisarTodos(req, res) {
        try {
            const { termo, tipo } = req.query;

            if (!termo || termo.trim() === '') {
                return res.status(400).json({ error: 'Termo de busca é obrigatório' });
            }

            let resultados = [];

            // Se tipo for especificado, busca apenas naquele tipo
            if (tipo && tipo !== 'todos') {
                switch (tipo) {
                    case 'PRESTADOR':
                        // Buscar prestadores diretamente
                        const prestadores = await prisma.usuario.findMany({
                            where: {
                                UsuarioTipo: 'PRESTADOR',
                                UsuarioStatus: 'ATIVO',
                                OR: [
                                    { UsuarioNome: { contains: termo, mode: 'insensitive' } },
                                    { UsuarioTelefone: { contains: termo } }
                                ]
                            },
                            select: {
                                UsuarioId: true,
                                UsuarioNome: true,
                                UsuarioTelefone: true,
                                UsuarioEnderecoId: true
                            },
                            take: 30
                        });

                        const prestadoresComEndereco = await Promise.all(
                            prestadores.map(async (p) => {
                                let enderecoCompleto = null;
                                if (p.UsuarioEnderecoId) {
                                    const endereco = await prisma.endereco.findFirst({
                                        where: {
                                            UsuEstId: p.UsuarioId,
                                            TipoRelacao: 'USUARIO'
                                        },
                                        select: {
                                            EnderecoCidade: true,
                                            EnderecoEstado: true,
                                            EnderecoBairro: true,
                                            EnderecoNumero: true,
                                            EnderecoRua: true
                                        }
                                    });
                                    if (endereco) {
                                        enderecoCompleto = endereco.EnderecoRua + ', N° ' + endereco.EnderecoNumero + ', ' + endereco.EnderecoBairro + '. ' + endereco.EnderecoCidade + ' - ' + endereco.EnderecoEstado;
                                    }
                                }
                                return {
                                    id: p.UsuarioId,
                                    nome: p.UsuarioNome,
                                    telefone: p.UsuarioTelefone,
                                    tipo: 'PRESTADOR',
                                    enderecoCompleto
                                };
                            })
                        );

                        resultados = prestadoresComEndereco;
                        break;
                    case 'EMPRESA':
                        // Buscar empresas diretamente
                        const empresas = await prisma.empresa.findMany({
                            where: {
                                EmpresaStatus: 'ATIVA',
                                OR: [
                                    { EmpresaNome: { contains: termo, mode: 'insensitive' } },
                                    { EmpresaTelefone: { contains: termo } }
                                ]
                            },
                            select: {
                                EmpresaId: true,
                                EmpresaNome: true,
                                EmpresaTelefone: true,
                                EmpresaDescricao: true
                            },
                            take: 30
                        });

                        resultados = empresas.map(e => ({
                            id: e.EmpresaId,
                            nome: e.EmpresaNome,
                            telefone: e.EmpresaTelefone,
                            descricao: e.EmpresaDescricao,
                            tipo: 'EMPRESA'
                        }));
                        break;
                    case 'ESTABELECIMENTO':
                        // Buscar estabelecimentos diretamente
                        const estabelecimentos = await prisma.estabelecimento.findMany({
                            where: {
                                EstabelecimentoStatus: 'ATIVO',
                                OR: [
                                    { EstabelecimentoNome: { contains: termo, mode: 'insensitive' } },
                                    { EstabelecimentoTelefone: { contains: termo } }
                                ]
                            },
                            include: {
                                empresa: {
                                    select: {
                                        EmpresaId: true,
                                        EmpresaNome: true
                                    }
                                },
                            },
                            take: 30
                        });

                        const estabelecimentoComEndereco = await Promise.all(
                            estabelecimentos.map(async (e) => {
                                let enderecoCompleto = null;
                                if (e.EstabelecimentoId) {
                                    const endereco = await prisma.endereco.findFirst({
                                        where: {
                                            UsuEstId: e.UsuarioId,
                                            TipoRelacao: 'ESTABELECIMENTO'
                                        },
                                        select: {
                                            EnderecoCidade: true,
                                            EnderecoEstado: true,
                                            EnderecoBairro: true,
                                            EnderecoNumero: true,
                                            EnderecoRua: true
                                        }
                                    });
                                    if (endereco) {
                                        enderecoCompleto = endereco.EnderecoRua + ', N° ' + endereco.EnderecoNumero + ', ' + endereco.EnderecoBairro + '. ' + endereco.EnderecoCidade + ' - ' + endereco.EnderecoEstado;
                                    }
                                }
                                return {
                                    id: e.EstabelecimentoId,
                                    nome: e.EstabelecimentoNome,
                                    telefone: e.EstabelecimentoTelefone,
                                    tipo: 'ESTABELECIMENTO',
                                    empresa: e.empresa ? {
                                        id: e.empresa.EmpresaId,
                                        nome: e.empresa.EmpresaNome
                                    } : null,
                                    enderecoCompleto
                                };
                            })
                        );

                        resultados = estabelecimentoComEndereco;
                        break;
                }
            } else {
                // Busca em todos os tipos (executar em paralelo)
                const [prestadores, empresas, estabelecimentos] = await Promise.all([
                    prisma.usuario.findMany({
                        where: {
                            UsuarioTipo: 'PRESTADOR',
                            UsuarioStatus: 'ATIVO',
                            OR: [
                                { UsuarioNome: { contains: termo, mode: 'insensitive' } },
                                { UsuarioEmail: { contains: termo, mode: 'insensitive' } },
                                { UsuarioTelefone: { contains: termo } }
                            ]
                        },
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioTelefone: true,
                            UsuarioEmail: true,
                            UsuarioEnderecoId: true
                        },
                        take: 30
                    }),
                    prisma.empresa.findMany({
                        where: {
                            EmpresaStatus: 'ATIVA',
                            OR: [
                                { EmpresaNome: { contains: termo, mode: 'insensitive' } },
                                { EmpresaEmail: { contains: termo, mode: 'insensitive' } },
                                { EmpresaTelefone: { contains: termo } },
                                { EmpresaCNPJ: { contains: termo } }
                            ]
                        },
                        select: {
                            EmpresaId: true,
                            EmpresaNome: true,
                            EmpresaTelefone: true,
                            EmpresaEmail: true,
                            EmpresaCNPJ: true,
                            EmpresaDescricao: true
                        },
                        take: 30
                    }),
                    prisma.estabelecimento.findMany({
                        where: {
                            EstabelecimentoStatus: 'ATIVO',
                            OR: [
                                { EstabelecimentoNome: { contains: termo, mode: 'insensitive' } },
                                { EstabelecimentoTelefone: { contains: termo } }
                            ]
                        },
                        include: {
                            empresa: {
                                select: {
                                    EmpresaId: true,
                                    EmpresaNome: true
                                }
                            },
                        },
                        take: 30
                    })
                ]);

                const prestadoresFormatados = await Promise.all(
                    prestadores.map(async (p) => {
                        let enderecoCompleto = null;
                        if (p.UsuarioEnderecoId) {
                            const endereco = await prisma.endereco.findFirst({
                                where: {
                                    UsuEstId: p.UsuarioId,
                                    TipoRelacao: 'USUARIO'
                                },
                                select: {
                                    EnderecoCidade: true,
                                    EnderecoEstado: true,
                                    EnderecoBairro: true,
                                    EnderecoNumero: true,
                                    EnderecoRua: true
                                }
                            });
                            if (endereco) {
                                enderecoCompleto = endereco.EnderecoRua + ', N° ' + endereco.EnderecoNumero + ', ' + endereco.EnderecoBairro + '. ' + endereco.EnderecoCidade + ' - ' + endereco.EnderecoEstado;
                            }
                        }
                        return {
                            id: p.UsuarioId,
                            nome: p.UsuarioNome,
                            telefone: p.UsuarioTelefone,
                            tipo: 'PRESTADOR',
                            enderecoCompleto
                        };
                    })
                );

                const empresasFormatadas = empresas.map(e => ({
                    id: e.EmpresaId,
                    nome: e.EmpresaNome,
                    telefone: e.EmpresaTelefone,
                    email: e.EmpresaEmail,
                    cnpj: e.EmpresaCNPJ,
                    descricao: e.EmpresaDescricao,
                    tipo: 'EMPRESA'
                }));

                const estabelecimentosFormatados = await Promise.all(
                    estabelecimentos.map(async (e) => {
                        let enderecoCompleto = null;
                        if (e.EstabelecimentoId) {
                            const endereco = await prisma.endereco.findFirst({
                                where: {
                                    UsuEstId: e.UsuarioId,
                                    TipoRelacao: 'ESTABELECIMENTO'
                                },
                                select: {
                                    EnderecoCidade: true,
                                    EnderecoEstado: true,
                                    EnderecoBairro: true,
                                    EnderecoNumero: true,
                                    EnderecoRua: true
                                }
                            });
                            if (endereco) {
                                enderecoCompleto = endereco.EnderecoRua + ', N° ' + endereco.EnderecoNumero + ', ' + endereco.EnderecoBairro + '. ' + endereco.EnderecoCidade + ' - ' + endereco.EnderecoEstado;
                            }
                        }
                        return {
                            id: e.EstabelecimentoId,
                            nome: e.EstabelecimentoNome,
                            telefone: e.EstabelecimentoTelefone,
                            tipo: 'ESTABELECIMENTO',
                            empresa: e.empresa ? {
                                id: e.empresa.EmpresaId,
                                nome: e.empresa.EmpresaNome
                            } : null,
                            enderecoCompleto
                        };
                    })
                );

                resultados = [...prestadoresFormatados, ...empresasFormatadas, ...estabelecimentosFormatados];
            }


            console.log('resultados = ', resultados);

            res.status(200).json({
                success: true,
                data: resultados,
                total: resultados.length
            });

        } catch (error) {
            console.error('Erro ao pesquisar todos:', error);
            res.status(500).json({ error: error.message });
        }
    }

}

module.exports = new PesquisaController();