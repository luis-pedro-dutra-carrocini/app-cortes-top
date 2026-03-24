const prisma = require('../prisma.js');

class EmpresaController {

    // Buscar empresas por nome ou termo (qualquer usuário logado)
    async buscarEmpresas(req, res) {
        try {
            const { q } = req.query;

            if (!q || q.trim() === '') {
                return res.status(400).json({ error: 'Termo de busca é obrigatório' });
            }

            const empresas = await prisma.empresa.findMany({
                where: {
                    EmpresaStatus: 'ATIVA',
                    OR: [
                        { EmpresaNome: { contains: q, mode: 'insensitive' } },
                        { EmpresaEmail: { contains: q, mode: 'insensitive' } },
                        { EmpresaTelefone: { contains: q } }
                    ]
                },
                select: {
                    EmpresaId: true,
                    EmpresaNome: true,
                    EmpresaTelefone: true,
                    EmpresaEmail: true
                },
                orderBy: {
                    EmpresaNome: 'asc'
                },
                take: 20 // Limite de resultados
            });

            const empresasFormatadas = empresas.map(emp => ({
                id: emp.EmpresaId,
                nome: emp.EmpresaNome,
                telefone: emp.EmpresaTelefone,
                email: emp.EmpresaEmail
            }));

            res.status(200).json({
                success: true,
                data: empresasFormatadas
            });

        } catch (error) {
            console.error('Erro ao buscar empresas:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // Buscar estabelecimentos de uma empresa
    async buscarEstabelecimentosPorEmpresa(req, res) {
        try {
            const { empresaId } = req.params;

            // Buscar estabelecimentos da empresa
            const estabelecimentos = await prisma.estabelecimento.findMany({
                where: {
                    EmpresaId: parseInt(empresaId),
                    EstabelecimentoStatus: 'ATIVO'
                },
                orderBy: {
                    EstabelecimentoNome: 'asc'
                }
            });

            // Para cada estabelecimento, buscar seu endereço separadamente
            const estabelecimentosComEndereco = await Promise.all(
                estabelecimentos.map(async (est) => {
                    // Buscar endereço na tabela Endereco
                    const endereco = await prisma.endereco.findFirst({
                        where: {
                            UsuEstId: est.EstabelecimentoId,
                            TipoRelacao: 'ESTABELECIMENTO'
                        },
                        select: {
                            EnderecoCidade: true,
                            EnderecoBairro: true,
                            EnderecoRua: true,
                            EnderecoNumero: true,
                            EnderecoCEP: true,
                            EnderecoEstado: true
                        }
                    });

                    return {
                        id: est.EstabelecimentoId,
                        nome: est.EstabelecimentoNome,
                        telefone: est.EstabelecimentoTelefone,
                        endereco: endereco ? {
                            cidade: endereco.EnderecoCidade,
                            bairro: endereco.EnderecoBairro,
                            rua: endereco.EnderecoRua,
                            numero: endereco.EnderecoNumero,
                            cep: endereco.EnderecoCEP,
                            estado: endereco.EnderecoEstado
                        } : null
                    };
                })
            );

            res.status(200).json({
                success: true,
                data: estabelecimentosComEndereco
            });

        } catch (error) {
            console.error('Erro ao buscar estabelecimentos:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // Buscar prestadores vinculados a um estabelecimento
    async buscarPrestadoresPorEstabelecimento(req, res) {
        try {
            const { estabelecimentoId } = req.params;
            const { nome, telefone } = req.query;

            // Construir filtro de busca
            const filtroUsuario = {
                UsuarioTipo: 'PRESTADOR',
                UsuarioStatus: 'ATIVO'
            };

            if (nome && nome.trim() !== '') {
                filtroUsuario.UsuarioNome = { contains: nome, mode: 'insensitive' };
            }

            if (telefone && telefone.trim() !== '') {
                filtroUsuario.UsuarioTelefone = { contains: telefone };
            }

            // Buscar vínculos ativos com o estabelecimento
            const vinculos = await prisma.usuarioEstabelecimento.findMany({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    UsuarioEstabelecimentoStatus: 'ATIVO',
                    usuario: filtroUsuario
                },
                include: {
                    usuario: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioTelefone: true,
                            UsuarioEmail: true
                        }
                    }
                },
                take: 20
            });

            const prestadoresFormatados = vinculos.map(v => ({
                id: v.usuario.UsuarioId,
                nome: v.usuario.UsuarioNome,
                telefone: v.usuario.UsuarioTelefone,
                email: v.usuario.UsuarioEmail
            }));

            res.status(200).json({
                success: true,
                data: prestadoresFormatados
            });

        } catch (error) {
            console.error('Erro ao buscar prestadores por estabelecimento:', error);
            res.status(500).json({ error: error.message });
        }
    }
}

module.exports = new EmpresaController();