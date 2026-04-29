// src/controllers/estabelecimentoController.js
const prisma = require('../prisma.js');

class EstabelecimentoController {

    // Criar novo estabelecimento (apenas EMPRESA)
    async criarEstabelecimento(req, res) {
        try {
            const empresaId = req.usuario.usuarioId;
            const {
                EstabelecimentoNome,
                EstabelecimentoTelefone,
                // Endereço
                EnderecoRua,
                EnderecoNumero,
                EnderecoComplemento,
                EnderecoBairro,
                EnderecoCidade,
                EnderecoEstado,
                EnderecoCEP
            } = req.body;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem cadastrar estabelecimentos'
                });
            }

            // Validações básicas
            if (!EstabelecimentoNome || EstabelecimentoNome.trim() === '') {
                return res.status(400).json({ error: 'Nome do estabelecimento é obrigatório' });
            }

            if (!EstabelecimentoTelefone || EstabelecimentoTelefone.trim() === '') {
                return res.status(400).json({ error: 'Telefone do estabelecimento é obrigatório' });
            }

            // Validações de endereço
            if (!EnderecoRua || EnderecoRua.trim() === '') {
                return res.status(400).json({ error: 'Rua é obrigatória' });
            }
            if (!EnderecoNumero || EnderecoNumero.trim() === '') {
                return res.status(400).json({ error: 'Número é obrigatório' });
            }
            if (!EnderecoBairro || EnderecoBairro.trim() === '') {
                return res.status(400).json({ error: 'Bairro é obrigatório' });
            }
            if (!EnderecoCidade || EnderecoCidade.trim() === '') {
                return res.status(400).json({ error: 'Cidade é obrigatória' });
            }
            if (!EnderecoEstado || EnderecoEstado.trim() === '') {
                return res.status(400).json({ error: 'Estado é obrigatório' });
            }
            if (!EnderecoCEP || EnderecoCEP.trim() === '') {
                return res.status(400).json({ error: 'CEP é obrigatório' });
            }

            // Verificar se a empresa existe
            const empresa = await prisma.empresa.findUnique({
                where: { EmpresaId: empresaId }
            });

            if (!empresa) {
                return res.status(404).json({ error: 'Empresa não encontrada' });
            }

            // Criar em transação
            const resultado = await prisma.$transaction(async (prisma) => {
                // 1. Criar endereço
                const endereco = await prisma.endereco.create({
                    data: {
                        UsuEstId: 0, // Será atualizado depois
                        TipoRelacao: 'ESTABELECIMENTO',
                        EnderecoRua: EnderecoRua.trim(),
                        EnderecoNumero: EnderecoNumero.trim(),
                        EnderecoComplemento: EnderecoComplemento?.trim() || null,
                        EnderecoBairro: EnderecoBairro.trim(),
                        EnderecoCidade: EnderecoCidade.trim(),
                        EnderecoEstado: EnderecoEstado.trim().toUpperCase(),
                        EnderecoCEP: EnderecoCEP.trim()
                    }
                });

                // 2. Criar estabelecimento
                const estabelecimento = await prisma.estabelecimento.create({
                    data: {
                        EmpresaId: empresaId,
                        EstabelecimentoNome: EstabelecimentoNome.trim(),
                        EstabelecimentoTelefone: EstabelecimentoTelefone.trim(),
                        EstabelecimentoEndereco: endereco.EnderecoId
                    }
                });

                // 3. Atualizar UsuEstId do endereço
                await prisma.endereco.update({
                    where: { EnderecoId: endereco.EnderecoId },
                    data: { UsuEstId: estabelecimento.EstabelecimentoId }
                });

                return {
                    ...estabelecimento,
                    endereco
                };
            });

            res.status(201).json({
                message: 'Estabelecimento criado com sucesso',
                data: resultado
            });

        } catch (error) {
            console.error('Erro ao criar estabelecimento:', error);
            res.status(500).json({
                error: 'Erro ao criar estabelecimento'
            });
        }
    }

    // Listar estabelecimentos da empresa logada
    async listarEstabelecimentos(req, res) {
        try {
            const empresaId = req.usuario.usuarioId;
            const { page = 1, limit = 10, status } = req.query;
            const skip = (page - 1) * limit;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem listar seus estabelecimentos'
                });
            }

            // Construir filtro
            const where = {
                EmpresaId: empresaId
            };

            // Filtrar por status se fornecido
            if (status) {
                where.EstabelecimentoStatus = status;
            }

            // Buscar estabelecimentos
            const estabelecimentos = await prisma.estabelecimento.findMany({
                where,
                skip: parseInt(skip),
                take: parseInt(limit),
                orderBy: {
                    EstabelecimentoNome: 'asc'
                }
            });

            // Buscar endereços separadamente
            const estabelecimentosComEndereco = await Promise.all(
                estabelecimentos.map(async (est) => {
                    const endereco = await prisma.endereco.findUnique({
                        where: { EnderecoId: est.EstabelecimentoEndereco }
                    });

                    // Buscar quantidade de usuários vinculados
                    const totalUsuarios = await prisma.usuarioEstabelecimento.count({
                        where: { EstabelecimentoId: est.EstabelecimentoId, UsuarioEstabelecimentoStatus: 'ATIVO' }
                    });

                    return {
                        ...est,
                        endereco,
                        totalUsuarios
                    };
                })
            );

            // Contar total para paginação
            const total = await prisma.estabelecimento.count({ where });

            res.status(200).json({
                data: estabelecimentosComEndereco,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            });

        } catch (error) {
            console.error('Erro ao listar estabelecimentos:', error);
            res.status(500).json({
                error: 'Erro ao listar estabelecimentos'
            });
        }
    }

    // Buscar estabelecimento por ID
    async buscarEstabelecimentoPorId(req, res) {
        try {
            const { estabelecimentoId } = req.params;
            const empresaId = req.usuario.usuarioId;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem visualizar detalhes do estabelecimento'
                });
            }

            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    EmpresaId: empresaId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({ error: 'Estabelecimento não encontrado' });
            }

            // Buscar endereço
            const endereco = await prisma.endereco.findUnique({
                where: { EnderecoId: estabelecimento.EstabelecimentoEndereco }
            });

            // Buscar usuários vinculados
            const usuariosVinculados = await prisma.usuarioEstabelecimento.findMany({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    UsuarioEstabelecimentoStatus: {
                        not: 'EXCLUIDO' // Opcional: filtrar excluídos
                    }
                },
                include: {
                    usuario: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true,
                            UsuarioTipo: true,
                            UsuarioStatus: true
                        }
                    }
                }
            });

            // Buscar serviços do estabelecimento
            const servicos = await prisma.servicoEstabelecimento.findMany({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    ServicoAtivo: true
                },
                include: {
                    servicos: {
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
            });

            res.status(200).json({
                data: {
                    ...estabelecimento,
                    endereco,
                    usuarios: usuariosVinculados.map(v => ({
                        ...v.usuario,
                        vinculoStatus: v.UsuarioEstabelecimentoStatus, // ADICIONA O STATUS
                        vinculoId: v.UsuarioEstabelecimentoId
                    })),
                    servicos: servicos.map(s => ({
                        // ... resto igual
                    }))
                }
            });

        } catch (error) {
            console.error('Erro ao buscar estabelecimento:', error);
            res.status(500).json({
                error: 'Erro ao buscar estabelecimento'
            });
        }
    }

    // Atualizar estabelecimento
    async atualizarEstabelecimento(req, res) {
        try {
            const estabelecimentoId = parseInt(req.params.id);
            const empresaId = req.usuario.usuarioId;
            const {
                EstabelecimentoNome,
                EstabelecimentoTelefone,
                EstabelecimentoStatus,
                // Endereço
                EnderecoRua,
                EnderecoNumero,
                EnderecoComplemento,
                EnderecoBairro,
                EnderecoCidade,
                EnderecoEstado,
                EnderecoCEP
            } = req.body;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem atualizar estabelecimentos'
                });
            }

            // Buscar estabelecimento
            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: estabelecimentoId,
                    EmpresaId: empresaId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({ error: 'Estabelecimento não encontrado' });
            }

            // Validações básicas se os campos foram fornecidos
            if (EstabelecimentoNome !== undefined && EstabelecimentoNome.trim() === '') {
                return res.status(400).json({ error: 'Nome do estabelecimento não pode ser vazio' });
            }

            if (EstabelecimentoTelefone !== undefined && EstabelecimentoTelefone.trim() === '') {
                return res.status(400).json({ error: 'Telefone do estabelecimento não pode ser vazio' });
            }

            // Atualizar em transação
            const resultado = await prisma.$transaction(async (prisma) => {
                // 1. Atualizar estabelecimento
                const estabelecimentoAtualizado = await prisma.estabelecimento.update({
                    where: { EstabelecimentoId: estabelecimentoId },
                    data: {
                        EstabelecimentoNome: EstabelecimentoNome ? EstabelecimentoNome.trim() : estabelecimento.EstabelecimentoNome,
                        EstabelecimentoTelefone: EstabelecimentoTelefone ? EstabelecimentoTelefone.trim() : estabelecimento.EstabelecimentoTelefone,
                        EstabelecimentoStatus: EstabelecimentoStatus !== undefined ? EstabelecimentoStatus : estabelecimento.EstabelecimentoStatus
                    }
                });

                // 2. Atualizar endereço se algum campo foi fornecido
                if (EnderecoRua || EnderecoNumero || EnderecoComplemento || EnderecoBairro || EnderecoCidade || EnderecoEstado || EnderecoCEP) {
                    // Buscar endereço atual
                    const enderecoAtual = await prisma.endereco.findUnique({
                        where: { EnderecoId: estabelecimento.EstabelecimentoEndereco }
                    });

                    await prisma.endereco.update({
                        where: { EnderecoId: estabelecimento.EstabelecimentoEndereco },
                        data: {
                            EnderecoRua: EnderecoRua?.trim() || enderecoAtual?.EnderecoRua,
                            EnderecoNumero: EnderecoNumero?.trim() || enderecoAtual?.EnderecoNumero,
                            EnderecoComplemento: EnderecoComplemento?.trim() || enderecoAtual?.EnderecoComplemento,
                            EnderecoBairro: EnderecoBairro?.trim() || enderecoAtual?.EnderecoBairro,
                            EnderecoCidade: EnderecoCidade?.trim() || enderecoAtual?.EnderecoCidade,
                            EnderecoEstado: EnderecoEstado?.trim()?.toUpperCase() || enderecoAtual?.EnderecoEstado,
                            EnderecoCEP: EnderecoCEP?.trim() || enderecoAtual?.EnderecoCEP
                        }
                    });
                }

                return estabelecimentoAtualizado;
            });

            // Buscar dados completos para retornar
            const enderecoFinal = await prisma.endereco.findUnique({
                where: { EnderecoId: estabelecimento.EstabelecimentoEndereco }
            });

            res.status(200).json({
                message: 'Estabelecimento atualizado com sucesso',
                data: {
                    ...resultado,
                    endereco: enderecoFinal
                }
            });

        } catch (error) {
            console.error('Erro ao atualizar estabelecimento:', error);
            res.status(500).json({
                error: 'Erro ao atualizar estabelecimento'
            });
        }
    }

    // Alternar status do estabelecimento (ativar/desativar)
    async alternarStatusEstabelecimento(req, res) {
        try {
            const estabelecimentoId = parseInt(req.params.estabelecimentoId);
            const empresaId = req.usuario.usuarioId;
            const { ativo } = req.body;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem alterar o status do estabelecimento'
                });
            }

            // Validar parâmetro
            if (ativo === undefined || typeof ativo !== 'boolean') {
                return res.status(400).json({
                    error: 'O campo "ativo" é obrigatório e deve ser true ou false'
                });
            }

            // Buscar estabelecimento
            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: estabelecimentoId,
                    EmpresaId: empresaId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({ error: 'Estabelecimento não encontrado' });
            }

            // Verificar se existem agendamentos ativos se for desativar
            if (!ativo) {
                const agendamentosAtivos = await prisma.agendamento.count({
                    where: {
                        EstabelecimentoId: estabelecimentoId,
                        AgendamentoStatus: {
                            in: ['PENDENTE', 'CONFIRMADO', 'EM_ANDAMENTO']
                        }
                    }
                });

                if (agendamentosAtivos > 0) {
                    return res.status(400).json({
                        error: 'Não é possível desativar um estabelecimento com agendamentos pendentes, confirmados ou em andamento'
                    });
                }
            }

            // Atualizar status
            const estabelecimentoAtualizado = await prisma.estabelecimento.update({
                where: { EstabelecimentoId: estabelecimentoId },
                data: {
                    EstabelecimentoStatus: ativo ? 'ATIVO' : 'INATIVO'
                }
            });

            res.status(200).json({
                message: `Estabelecimento ${ativo ? 'ativado' : 'desativado'} com sucesso`,
                data: estabelecimentoAtualizado
            });

        } catch (error) {
            console.error('Erro ao alterar status do estabelecimento:', error);
            res.status(500).json({ error: 'Erro ao alterar status do estabelecimento' });
        }
    }

    // Vincular usuário ao estabelecimento
    async vincularUsuario(req, res) {
        try {
            const { estabelecimentoId, usuarioId } = req.params;
            const empresaId = req.usuario.usuarioId;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem vincular usuários'
                });
            }

            // Verificar se o estabelecimento pertence à empresa
            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    EmpresaId: empresaId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({ error: 'Estabelecimento não encontrado' });
            }

            // Verificar se o usuário existe e é PRESTADOR
            const usuario = await prisma.usuario.findFirst({
                where: {
                    UsuarioId: parseInt(usuarioId),
                    UsuarioTipo: 'PRESTADOR',
                    UsuarioStatus: 'ATIVO'
                }
            });

            if (!usuario) {
                return res.status(404).json({ error: 'Prestador não encontrado ou não está ativo' });
            }

            // Verificar se já está vinculado
            const vinculoExistente = await prisma.usuarioEstabelecimento.findFirst({
                where: {
                    UsuarioId: parseInt(usuarioId),
                    EstabelecimentoId: parseInt(estabelecimentoId)
                }
            });

            if (vinculoExistente) {
                return res.status(400).json({ error: 'Usuário já está vinculado a este estabelecimento' });
            }

            // Criar vínculo
            const vinculo = await prisma.usuarioEstabelecimento.create({
                data: {
                    UsuarioId: parseInt(usuarioId),
                    EstabelecimentoId: parseInt(estabelecimentoId)
                },
                include: {
                    usuario: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true,
                            UsuarioTipo: true
                        }
                    },
                    estabelecimento: {
                        select: {
                            EstabelecimentoId: true,
                            EstabelecimentoNome: true
                        }
                    }
                }
            });

            res.status(201).json({
                message: 'Usuário vinculado com sucesso',
                data: vinculo
            });

        } catch (error) {
            console.error('Erro ao vincular usuário:', error);
            res.status(500).json({ error: 'Erro ao vincular usuário' });
        }
    }

    // Desvincular usuário do estabelecimento
    async desvincularUsuario(req, res) {
        try {
            const { estabelecimentoId, usuarioId } = req.params;
            const empresaId = req.usuario.usuarioId;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem desvincular usuários'
                });
            }

            // Verificar se o estabelecimento pertence à empresa
            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    EmpresaId: empresaId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({ error: 'Estabelecimento não encontrado' });
            }

            // Verificar se o vínculo existe
            const vinculo = await prisma.usuarioEstabelecimento.findFirst({
                where: {
                    UsuarioId: parseInt(usuarioId),
                    EstabelecimentoId: parseInt(estabelecimentoId)
                }
            });

            if (!vinculo) {
                return res.status(404).json({ error: 'Vínculo não encontrado' });
            }

            // Verificar se existem agendamentos ativos para este usuário no estabelecimento
            const agendamentosAtivos = await prisma.agendamento.count({
                where: {
                    PrestadorId: parseInt(usuarioId),
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    AgendamentoStatus: {
                        in: ['PENDENTE', 'CONFIRMADO', 'EM_ANDAMENTO']
                    }
                }
            });

            if (agendamentosAtivos > 0) {
                return res.status(400).json({
                    error: 'Não é possível desvincular um prestador com agendamentos ativos'
                });
            }

            // Remover vínculo
            await prisma.usuarioEstabelecimento.delete({
                where: {
                    UsuarioEstabelecimentoId: vinculo.UsuarioEstabelecimentoId
                }
            });

            res.status(200).json({
                message: 'Usuário desvinculado com sucesso'
            });

        } catch (error) {
            console.error('Erro ao desvincular usuário:', error);
            res.status(500).json({ error: 'Erro ao desvincular usuário' });
        }
    }

    // Listar usuários vinculados a um estabelecimento
    async listarUsuariosVinculados(req, res) {
        try {
            const { estabelecimentoId } = req.params;
            const empresaId = req.usuario.usuarioId;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem listar usuários vinculados'
                });
            }

            // Verificar se o estabelecimento pertence à empresa
            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    EmpresaId: empresaId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({ error: 'Estabelecimento não encontrado' });
            }

            // Buscar usuários vinculados
            const vinculos = await prisma.usuarioEstabelecimento.findMany({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId)
                },
                include: {
                    usuario: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true,
                            UsuarioTipo: true,
                            UsuarioStatus: true
                        }
                    }
                },
                orderBy: {
                    usuario: {
                        UsuarioNome: 'asc'
                    }
                }
            });

            res.status(200).json({
                data: vinculos.map(v => v.usuario)
            });

        } catch (error) {
            console.error('Erro ao listar usuários vinculados:', error);
            res.status(500).json({ error: 'Erro ao listar usuários vinculados' });
        }
    }

    // Listar vínculos do estabelecimento
    async listarVinculos(req, res) {
        try {
            const { estabelecimentoId } = req.params;
            const empresaId = req.usuario.usuarioId;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    success: false,
                    error: 'Apenas empresas podem listar vínculos'
                });
            }

            // Verificar se o estabelecimento pertence à empresa
            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    EmpresaId: empresaId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({
                    success: false,
                    error: 'Estabelecimento não encontrado'
                });
            }

            // Buscar vínculos (excluindo EXCLUIDO)
            const vinculos = await prisma.usuarioEstabelecimento.findMany({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    UsuarioEstabelecimentoStatus: {
                        not: 'EXCLUIDO'
                    }
                },
                include: {
                    usuario: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true,
                            UsuarioTipo: true,
                            UsuarioStatus: true
                        }
                    }
                },
                orderBy: {
                    UsuarioEstabelecimentoDtCriacao: 'desc'
                }
            });

            // Garantir que o status nunca seja null
            const vinculosFormatados = vinculos.map(vinculo => ({
                ...vinculo,
                UsuarioEstabelecimentoStatus: vinculo.UsuarioEstabelecimentoStatus || 'DESCONHECIDO',
                usuario: {
                    ...vinculo.usuario,
                    UsuarioNome: vinculo.usuario?.UsuarioNome || 'Nome não informado',
                    UsuarioEmail: vinculo.usuario?.UsuarioEmail || '',
                    UsuarioTelefone: vinculo.usuario?.UsuarioTelefone || ''
                }
            }));

            //console.log('Vínculos brutos do banco:', JSON.stringify(vinculos, null, 2));
            //console.log('Vínculos formatados:', JSON.stringify(vinculosFormatados, null, 2));


            res.status(200).json({
                success: true,
                data: vinculosFormatados
            });

        } catch (error) {
            console.error('Erro ao listar vínculos:', error);
            res.status(500).json({
                success: false,
                error: 'Erro ao listar vínculos'
            });
        }
    }

    // Solicitar vínculo (estabelecimento solicita)
    async solicitarVinculo(req, res) {
        try {
            const { estabelecimentoId, usuarioId } = req.params;
            const empresaId = req.usuario.usuarioId;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    success: false,
                    error: 'Apenas empresas podem solicitar vínculos'
                });
            }

            // Verificar se o estabelecimento pertence à empresa
            const estabelecimento = await prisma.estabelecimento.findFirst({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    EmpresaId: empresaId
                }
            });

            if (!estabelecimento) {
                return res.status(404).json({
                    success: false,
                    error: 'Estabelecimento não encontrado'
                });
            }

            // Verificar se o usuário existe e é PRESTADOR
            const usuario = await prisma.usuario.findFirst({
                where: {
                    UsuarioId: parseInt(usuarioId),
                    UsuarioTipo: 'PRESTADOR',
                    UsuarioStatus: 'ATIVO'
                }
            });

            if (!usuario) {
                return res.status(404).json({
                    success: false,
                    error: 'Prestador não encontrado ou não está ativo'
                });
            }

            // Verificar se já existe vínculo não excluído
            const vinculoExistente = await prisma.usuarioEstabelecimento.findFirst({
                where: {
                    UsuarioId: parseInt(usuarioId),
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    UsuarioEstabelecimentoStatus: {
                        not: 'EXCLUIDO'
                    }
                }
            });

            if (vinculoExistente) {
                return res.status(400).json({
                    success: false,
                    error: 'Já existe um vínculo ou solicitação entre este prestador e estabelecimento'
                });
            }

            // Criar solicitação
            const vinculo = await prisma.usuarioEstabelecimento.create({
                data: {
                    UsuarioId: parseInt(usuarioId),
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    UsuarioEstabelecimentoStatus: 'SOLICITADOEST'
                },
                include: {
                    usuario: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true
                        }
                    },
                    estabelecimento: {
                        select: {
                            EstabelecimentoId: true,
                            EstabelecimentoNome: true
                        }
                    }
                }
            });

            res.status(201).json({
                success: true,
                message: 'Solicitação enviada com sucesso',
                data: vinculo
            });

        } catch (error) {
            console.error('Erro ao solicitar vínculo:', error);
            res.status(500).json({
                success: false,
                error: 'Erro ao solicitar vínculo'
            });
        }
    }

    // Aceitar vínculo (prestador aceita)
    async aceitarVinculo(req, res) {
        try {
            const { vinculoId } = req.params;
            const usuarioId = req.usuario.usuarioId;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    success: false,
                    error: 'Apenas prestadores podem aceitar solicitações'
                });
            }

            // Buscar vínculo
            const vinculo = await prisma.usuarioEstabelecimento.findUnique({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) }
            });

            if (!vinculo) {
                return res.status(404).json({
                    success: false,
                    error: 'Vínculo não encontrado'
                });
            }

            // Verificar se o vínculo pertence ao prestador
            if (vinculo.UsuarioId !== usuarioId) {
                return res.status(403).json({
                    success: false,
                    error: 'Você só pode aceitar seus próprios vínculos'
                });
            }

            // Verificar se o status permite aceitação
            if (vinculo.UsuarioEstabelecimentoStatus !== 'SOLICITADOEST' && vinculo.UsuarioEstabelecimentoStatus !== 'RECUSADOPRE') {
                return res.status(400).json({
                    success: false,
                    error: 'Este vínculo não pode ser aceito no status atual'
                });
            }

            // Aceitar vínculo
            const vinculoAtualizado = await prisma.usuarioEstabelecimento.update({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) },
                data: { UsuarioEstabelecimentoStatus: 'ATIVO' }
            });

            res.status(200).json({
                success: true,
                message: 'Vínculo aceito com sucesso',
                data: vinculoAtualizado
            });

        } catch (error) {
            console.error('Erro ao aceitar vínculo:', error);
            res.status(500).json({
                success: false,
                error: 'Erro ao aceitar vínculo'
            });
        }
    }

    // Recusar vínculo (prestador recusa)
    async recusarVinculo(req, res) {
        try {
            const { vinculoId } = req.params;
            const usuarioId = req.usuario.usuarioId;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    success: false,
                    error: 'Apenas prestadores podem recusar solicitações'
                });
            }

            // Buscar vínculo
            const vinculo = await prisma.usuarioEstabelecimento.findUnique({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) }
            });

            if (!vinculo) {
                return res.status(404).json({
                    success: false,
                    error: 'Vínculo não encontrado'
                });
            }

            // Verificar se o vínculo pertence ao prestador
            if (vinculo.UsuarioId !== usuarioId) {
                return res.status(403).json({
                    success: false,
                    error: 'Você só pode recusar seus próprios vínculos'
                });
            }

            // Verificar se o status permite recusa
            if (vinculo.UsuarioEstabelecimentoStatus !== 'SOLICITADOEST') {
                return res.status(400).json({
                    success: false,
                    error: 'Este vínculo não pode ser recusado no status atual'
                });
            }

            // Excluir vínculo (soft delete)
            await prisma.usuarioEstabelecimento.update({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) },
                data: { UsuarioEstabelecimentoStatus: 'RECUSADOPRE' }
            });

            res.status(200).json({
                success: true,
                message: 'Solicitação recusada com sucesso'
            });

        } catch (error) {
            console.error('Erro ao recusar vínculo:', error);
            res.status(500).json({
                success: false,
                error: 'Erro ao recusar vínculo'
            });
        }
    }

    // Desativar vínculo (estabelecimento desativa)
    async desativarVinculo(req, res) {
        try {
            const { vinculoId } = req.params;
            const empresaId = req.usuario.usuarioId;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    success: false,
                    error: 'Apenas empresas podem desativar vínculos'
                });
            }

            // Buscar vínculo com estabelecimento
            const vinculo = await prisma.usuarioEstabelecimento.findUnique({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) },
                include: {
                    estabelecimento: true
                }
            });

            if (!vinculo) {
                return res.status(404).json({
                    success: false,
                    error: 'Vínculo não encontrado'
                });
            }

            // Verificar se o estabelecimento pertence à empresa
            if (vinculo.estabelecimento.EmpresaId !== empresaId) {
                return res.status(403).json({
                    success: false,
                    error: 'Você só pode desativar vínculos dos seus estabelecimentos'
                });
            }

            // Desativar vínculo
            await prisma.usuarioEstabelecimento.update({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) },
                data: { UsuarioEstabelecimentoStatus: 'INATIVO' }
            });

            res.status(200).json({
                success: true,
                message: 'Vínculo desativado com sucesso'
            });

        } catch (error) {
            console.error('Erro ao desativar vínculo:', error);
            res.status(500).json({
                success: false,
                error: 'Erro ao desativar vínculo'
            });
        }
    }

    // Desativar vínculo (estabelecimento desativa)
    async reativarVinculo(req, res) {
        try {
            const { vinculoId } = req.params;
            const empresaId = req.usuario.usuarioId;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    success: false,
                    error: 'Apenas empresas podem desativar vínculos'
                });
            }

            // Buscar vínculo com estabelecimento
            const vinculo = await prisma.usuarioEstabelecimento.findUnique({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) },
                include: {
                    estabelecimento: true
                }
            });

            if (!vinculo) {
                return res.status(404).json({
                    success: false,
                    error: 'Vínculo não encontrado'
                });
            }

            // Verificar se o estabelecimento pertence à empresa
            if (vinculo.estabelecimento.EmpresaId !== empresaId) {
                return res.status(403).json({
                    success: false,
                    error: 'Você só pode reativar vínculos dos seus estabelecimentos'
                });
            }

            // Desativar vínculo
            await prisma.usuarioEstabelecimento.update({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) },
                data: { UsuarioEstabelecimentoStatus: 'ATIVO' }
            });

            res.status(200).json({
                success: true,
                message: 'Vínculo reativado com sucesso'
            });

        } catch (error) {
            console.error('Erro ao reativar vínculo:', error);
            res.status(500).json({
                success: false,
                error: 'Erro ao reativar vínculo'
            });
        }
    }

    // Excluir vínculo (soft delete - ambos os lados podem excluir)
    async excluirVinculo(req, res) {
        try {
            const { vinculoId } = req.params;
            const usuarioId = req.usuario.usuarioId;
            const tipoUsuario = req.usuario.usuarioTipo;

            // Buscar vínculo
            const vinculo = await prisma.usuarioEstabelecimento.findUnique({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) },
                include: {
                    estabelecimento: true
                }
            });

            if (!vinculo) {
                return res.status(404).json({
                    success: false,
                    error: 'Vínculo não encontrado'
                });
            }

            // Verificar permissão
            if (tipoUsuario === 'PRESTADOR') {
                // Prestador só pode excluir seus próprios vínculos
                if (vinculo.UsuarioId !== usuarioId) {
                    return res.status(403).json({
                        success: false,
                        error: 'Você só pode excluir seus próprios vínculos'
                    });
                }
            } else if (tipoUsuario === 'EMPRESA') {
                // Empresa só pode excluir vínculos dos seus estabelecimentos
                if (vinculo.estabelecimento.EmpresaId !== usuarioId) {
                    return res.status(403).json({
                        success: false,
                        error: 'Você só pode excluir vínculos dos seus estabelecimentos'
                    });
                }
            } else {
                return res.status(403).json({
                    success: false,
                    error: 'Tipo de usuário não autorizado'
                });
            }

            const vinculoEst = await prisma.usuarioEstabelecimento.findFirst({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) },
                select: {
                    UsuarioId: true,
                    EstabelecimentoId: true
                }
            });

            //console.log('vinculoEst = ', vinculoEst)

            // Obter os serviços do estabelecimento e desvincular cada um deles
            if (vinculoEst) {
                const sevicosEstabelecimentos = await prisma.servicoEstabelecimento.findMany({
                    where: { EstabelecimentoId: vinculoEst.EstabelecimentoId }
                });

                //console.log('sevicosestabelecimentos = ', sevicosEstabelecimentos)

                for (const servicoEstabelecimento of sevicosEstabelecimentos) {
                    await prisma.servico.updateMany({
                        where: { PrestadorId: vinculoEst.UsuarioId, ServicoEstabelecimentoId: servicoEstabelecimento.ServicoEstabelecimentoId },
                        data: { ServicoAtivo: false }
                    });
                }
            }

            // Soft delete
            await prisma.usuarioEstabelecimento.update({
                where: { UsuarioEstabelecimentoId: parseInt(vinculoId) },
                data: { UsuarioEstabelecimentoStatus: 'EXCLUIDO' }
            });

            res.status(200).json({
                success: true,
                message: 'Vínculo excluído com sucesso'
            });

        } catch (error) {
            console.error('Erro ao excluir vínculo:', error);
            res.status(500).json({
                success: false,
                error: 'Erro ao excluir vínculo'
            });
        }
    }

    // Listar prestadores disponíveis para vincular (com busca opcional)
    async listarPrestadoresDisponiveis(req, res) {
        try {
            const { estabelecimentoId } = req.params;
            const { busca, page = 1, limit = 20 } = req.query; // Parâmetros de busca e paginação
            const empresaId = req.usuario.usuarioId;

            // Verificar permissões...

            // Buscar IDs dos usuários já vinculados
            const usuariosVinculados = await prisma.usuarioEstabelecimento.findMany({
                where: {
                    EstabelecimentoId: parseInt(estabelecimentoId),
                    UsuarioEstabelecimentoStatus: {
                        not: 'EXCLUIDO'
                    }
                },
                select: { UsuarioId: true }
            });

            const idsVinculados = usuariosVinculados.map(v => v.UsuarioId);

            // Construir filtro de busca
            const where = {
                UsuarioTipo: 'PRESTADOR',
                UsuarioStatus: 'ATIVO',
                UsuarioId: {
                    notIn: idsVinculados.length > 0 ? idsVinculados : [0]
                }
            };

            // Adicionar filtro de busca se fornecido
            if (busca && busca.trim() !== '') {
                where.OR = [
                    { UsuarioNome: { contains: busca, mode: 'insensitive' } },
                    { UsuarioEmail: { contains: busca, mode: 'insensitive' } },
                    { UsuarioTelefone: { contains: busca } }
                ];
            }

            // Buscar prestadores com paginação
            const prestadores = await prisma.usuario.findMany({
                where,
                select: {
                    UsuarioId: true,
                    UsuarioNome: true,
                    UsuarioEmail: true,
                    UsuarioTelefone: true
                },
                orderBy: { UsuarioNome: 'asc' },
                skip: (page - 1) * limit,
                take: parseInt(limit)
            });

            // Contar total para paginação
            const total = await prisma.usuario.count({ where });

            res.status(200).json({
                success: true,
                data: prestadores,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            });

        } catch (error) {
            console.error('Erro ao listar prestadores disponíveis:', error);
            res.status(500).json({ success: false, error: 'Erro ao listar prestadores disponíveis' });
        }
    }

    async listarVinculosPrestador(req, res) {
        try {
            const prestadorId = req.usuario.usuarioId;

            const vinculos = await prisma.usuarioEstabelecimento.findMany({
                where: {
                    UsuarioId: prestadorId,
                    UsuarioEstabelecimentoStatus: {
                        not: 'EXCLUIDO'
                    }
                },
                include: {
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
                orderBy: {
                    UsuarioEstabelecimentoDtCriacao: 'desc'
                }
            });

            //console.log('vinculos = ', vinculos)

            res.status(200).json({
                success: true,
                data: vinculos
            });
        } catch (error) {
            console.error('Erro ao listar vínculos do prestador:', error);
            res.status(500).json({ error: 'Erro ao listar vínculos do prestador' });
        }
    }

}

module.exports = new EstabelecimentoController();