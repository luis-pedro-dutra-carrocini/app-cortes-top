// src/controllers/usuarioController.js
const prisma = require('../prisma.js');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

class UsuarioController {

    // Login do usuário
    async login(req, res) {
        try {
            const { UsuarioEmail, UsuarioSenha, UsuarioTipo } = req.body;

            if (!UsuarioEmail || !UsuarioSenha || !UsuarioTipo) {
                return res.status(400).json({
                    error: 'E-mail, senha e tipo de usuário são obrigatórios'
                });
            }

            let usuario = null;
            let usuarioSemSenha = null;
            let token = null;

            // Verificar o tipo de usuário e buscar na tabela correspondente
            if (UsuarioTipo === 'EMPRESA') {
                // Buscar na tabela Empresa
                let empresa = await prisma.empresa.findFirst({
                    where: {
                        EmpresaEmail: UsuarioEmail.trim(),
                        EmpresaStatus: { in: ['ATIVA', 'BLOQUEADA', 'BLOQUEADAPAGAMENTO'] }
                    }
                });

                if (!empresa) {
                    //return res.status(401).json({
                    return res.status(403).json({
                        error: 'E-mail ou senha inválidos'
                    });
                }

                if (empresa.EmpresaStatus === 'BLOQUEADA') {
                    return res.status(403).json({
                        error: 'Conta bloqueada. Entre em contato com o suporte para mais informações.'
                    });
                }

                // Verificar senha
                const senhaValida = await bcrypt.compare(UsuarioSenha, empresa.EmpresaSenha);

                if (!senhaValida) {
                    //return res.status(401).json({]
                    return res.status(403).json({
                        error: 'E-mail ou senha inválidos'
                    });
                }

                // Gerar token JWT
                token = jwt.sign(
                    {
                        usuarioId: empresa.EmpresaId,
                        usuarioTipo: 'EMPRESA',
                        usuarioEmail: empresa.EmpresaEmail
                    },
                    process.env.JWT_SECRET,
                    { expiresIn: '24h' }
                );

                let UsuarioAtivo = true;
                if (empresa.EmpresaStatus === 'BLOQUEADAPAGAMENTO') {
                    UsuarioAtivo = false;
                }

                // Adaptar para o formato esperado pelo frontend (similar a Usuario)
                usuarioSemSenha = {
                    UsuarioId: empresa.EmpresaId,
                    UsuarioNome: empresa.EmpresaNome,
                    UsuarioEmail: empresa.EmpresaEmail,
                    UsuarioTelefone: empresa.EmpresaTelefone,
                    UsuarioTipo: 'EMPRESA',
                    UsuarioDtCriacao: empresa.EmpresaDtCriacao,
                    UsuarioAtivo: UsuarioAtivo,
                    EmpresaCNPJ: empresa.EmpresaCNPJ
                };

                // Atualizar último login
                const dataLocal = new Date();

                // Ajusta para o fuso de Brasília (UTC -3)
                const dataBrasilia = new Date(dataLocal.getTime() - (3 * 60 * 60 * 1000));
                
                await prisma.empresa.update({
                    where: { EmpresaId: empresa.EmpresaId },
                    data: { EmpresaUltimoLogin: dataBrasilia }
                });

            } else {
                // Buscar na tabela Usuario (CLIENTE ou PRESTADOR)
                usuario = await prisma.usuario.findFirst({
                    where: {
                        UsuarioEmail: UsuarioEmail.trim(),
                        UsuarioTipo: UsuarioTipo,
                        UsuarioStatus: { in: ['ATIVO', 'BLOQUEADO', 'BLOQUEADOPAGAMENTO'] }
                    }
                });

                if (!usuario) {
                    //return res.status(401).json({
                    return res.status(403).json({
                        error: 'E-mail ou senha inválidos'
                    });
                }

                if (usuario.UsuarioStatus === 'BLOQUEADO') {
                    return res.status(403).json({
                        error: 'Conta bloqueada. Entre em contato com o suporte para mais informações.'
                    });
                }

                // Verificar senha
                const senhaValida = await bcrypt.compare(UsuarioSenha, usuario.UsuarioSenha);

                if (!senhaValida) {
                    //return res.status(401).json({
                    return res.status(403).json({
                        error: 'E-mail ou senha inválidos'
                    });
                }

                // Gerar token JWT
                token = jwt.sign(
                    {
                        usuarioId: usuario.UsuarioId,
                        usuarioTipo: usuario.UsuarioTipo,
                        usuarioEmail: usuario.UsuarioEmail
                    },
                    process.env.JWT_SECRET,
                    { expiresIn: '24h' }
                );

                let UsuarioAtivo = true;
                if (usuario.UsuarioStatus === 'BLOQUEADOPAGAMENTO') {
                    UsuarioAtivo = false;
                }

                // Construir objeto base do usuário
                usuarioSemSenha = {
                    UsuarioId: usuario.UsuarioId,
                    UsuarioNome: usuario.UsuarioNome,
                    UsuarioEmail: usuario.UsuarioEmail,
                    UsuarioTelefone: usuario.UsuarioTelefone,
                    UsuarioTipo: usuario.UsuarioTipo,
                    UsuarioDtCriacao: usuario.UsuarioDtCriacao,
                    UsuarioAtivo: UsuarioAtivo
                };

                // Atualizar último login
                const dataLocal = new Date();

                // Ajusta para o fuso de Brasília (UTC -3)
                const dataBrasilia = new Date(dataLocal.getTime() - (3 * 60 * 60 * 1000));

                await prisma.usuario.update({
                    where: { UsuarioId: usuario.UsuarioId },
                    data: { UsuarioUltimoLogin: dataBrasilia }
                });

                // Buscar endereço SEPARADAMENTE se for PRESTADOR
                if (usuario.UsuarioTipo === 'PRESTADOR' && usuario.UsuarioEnderecoId) {
                    const endereco = await prisma.endereco.findUnique({
                        where: { EnderecoId: usuario.UsuarioEnderecoId }
                    });

                    if (endereco) {
                        usuarioSemSenha = {
                            ...usuarioSemSenha,
                            EnderecoCEP: endereco.EnderecoCEP,
                            EnderecoRua: endereco.EnderecoRua,
                            EnderecoNumero: endereco.EnderecoNumero,
                            EnderecoComplemento: endereco.EnderecoComplemento,
                            EnderecoBairro: endereco.EnderecoBairro,
                            EnderecoCidade: endereco.EnderecoCidade,
                            EnderecoEstado: endereco.EnderecoEstado
                        };
                    }
                }
            }

            res.status(200).json({
                message: 'Login realizado com sucesso',
                token,
                usuario: usuarioSemSenha
            });

        } catch (error) {
            console.error('Erro no login:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Buscar Usuário por ID (qualquer usuário logado pode ver perfil de prestadores e empresas, mas só pode ver perfil de clientes se for prestador ou empresa)
    async buscarUsuarioId(req, res) {
        try {
            const { usuarioId } = req.params;

            let usuario = await prisma.usuario.findFirst({
                where: {
                    UsuarioId: parseInt(usuarioId)
                },
                select: {
                    UsuarioId: true,
                    UsuarioNome: true,
                    UsuarioTelefone: true,
                    UsuarioEmail: true,
                    UsuarioTipo: true,
                    UsuarioStatus: true,
                }
            });

            if (!usuario) {
                return res.status(404).json({ error: 'Usuário não encontrado' });
            }

            if (usuario.UsuarioTipo === 'CLIENTE' && req.usuario.usuarioTipo === 'CLIENTE' && req.usuario.usuarioId !== usuario.UsuarioId) {
                return res.status(403).json({
                    error: 'Clientes não podem acessar o perfil de outros clientes'
                });
            }

            if (usuario.UsuarioStatus === 'EXCLUIDO') {
                usuario.UsuarioNome = 'Usuário Excluído';
                usuario.UsuarioEmail = null;
                usuario.UsuarioTelefone = null;
            }

            res.status(200).json({ data: usuario });

        } catch (error) {
            console.error('Erro ao buscar usuário:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Listar últimos prestadores utilizados pelo cliente (apenas CLIENTE)
    async listarUltimosPrestadoresCliente(req, res) {
        try {
            // Verificar se o usuário é CLIENTE
            if (req.usuario.usuarioTipo !== 'CLIENTE') {
                return res.status(403).json({
                    error: 'Apenas clientes podem acessar seus últimos prestadores'
                });
            }

            const clienteId = req.usuario.usuarioId;

            // Buscar os últimos 5 prestadores com quem o cliente já agendou
            const ultimosPrestadores = await prisma.agendamento.findMany({
                where: {
                    ClienteId: clienteId
                },
                select: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true,
                            UsuarioTipo: true
                        }
                    },
                    AgendamentoDtCriacao: true
                },
                distinct: ['PrestadorId'],
                orderBy: {
                    AgendamentoDtCriacao: 'desc'
                },
                take: 5
            });

            // Extrair apenas os dados do prestador
            const prestadores = ultimosPrestadores.map(item => ({
                ...item.prestador,
                ultimoAgendamento: item.AgendamentoDtCriacao
            }));

            // Remover prestadores bloqueados ou excluídos
            const prestadoresFiltrados = prestadores.filter(p => p.UsuarioStatus !== 'BLOQUEADO' && p.UsuarioStatus !== 'EXCLUIDO' && p.UsuarioStatus !== 'BLOQUEADOPAGAMENTO');

            res.status(200).json({
                data: prestadoresFiltrados,
                total: prestadoresFiltrados.length
            });

        } catch (error) {
            console.error('Erro ao listar últimos prestadores:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Pesquisar prestadores por nome ou telefone (qualquer usuário logado)
    async pesquisarPrestadores(req, res) {
        try {
            const { nome, telefone } = req.query;

            // Validar se pelo menos um parâmetro foi fornecido
            if (!nome && !telefone) {
                return res.status(400).json({
                    error: 'Informe nome ou telefone para pesquisa'
                });
            }

            // Construir filtro de busca
            const where = {
                UsuarioTipo: 'PRESTADOR',
                UsuarioStatus: 'ATIVO' // Buscar apenas prestadores ativos
            };

            if (nome && nome.trim() !== '') {
                where.UsuarioNome = {
                    contains: nome.trim(),
                    mode: 'insensitive' // Case insensitive
                };
            }

            if (telefone && telefone.trim() !== '') {
                where.UsuarioTelefone = {
                    contains: telefone.trim()
                };
            }

            // Buscar prestadores
            const prestadores = await prisma.usuario.findMany({
                where: where,
                select: {
                    UsuarioId: true,
                    UsuarioNome: true,
                    UsuarioEmail: true,
                    UsuarioTelefone: true,
                    UsuarioTipo: true
                },
                orderBy: {
                    UsuarioNome: 'asc'
                },
                take: 20 // Limitar a 20 resultados
            });

            res.status(200).json({
                data: prestadores,
                total: prestadores.length,
                termo: { nome, telefone }
            });

        } catch (error) {
            console.error('Erro ao pesquisar prestadores:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Cadastrar usuário (público - não precisa estar logado)
    async cadastrarUsuario(req, res) {
        try {
            const {
                UsuarioNome,
                UsuarioTelefone,
                UsuarioEmail,
                UsuarioSenha,
                UsuarioTipo,
                // Campos de endereço (opcionais para CLIENTE/EMPRESA, obrigatórios para PRESTADOR)
                EnderecoRua,
                EnderecoNumero,
                EnderecoComplemento,
                EnderecoBairro,
                EnderecoCidade,
                EnderecoEstado,
                EnderecoCEP,
                //Caso for empresa
                EmpresaCNPJ
            } = req.body;

            // Validações básicas
            if (!UsuarioNome || UsuarioNome.trim() === '') {
                return res.status(400).json({ error: 'Nome é obrigatório' });
            }

            if (!UsuarioTelefone || UsuarioTelefone.trim() === '') {
                return res.status(400).json({ error: 'Telefone é obrigatório' });
            }

            if (!UsuarioEmail || UsuarioEmail.trim() === '') {
                return res.status(400).json({ error: 'E-mail é obrigatório' });
            }

            if (!UsuarioSenha || UsuarioSenha.trim() === '') {
                return res.status(400).json({ error: 'Senha é obrigatória' });
            }

            if (!UsuarioTipo || UsuarioTipo.trim() === '') {
                return res.status(400).json({ error: 'Tipo de usuário é obrigatório' });
            } else if (!['CLIENTE', 'PRESTADOR', 'EMPRESA'].includes(UsuarioTipo.trim().toUpperCase())) {
                return res.status(400).json({
                    error: 'Tipo de usuário inválido. Deve ser "CLIENTE", "PRESTADOR" ou "EMPRESA"'
                });
            }

            // Validações específicas para PRESTADOR (endereço obrigatório)
            const tipo = UsuarioTipo.trim().toUpperCase();

            if (tipo === 'PRESTADOR') {
                if (!EnderecoRua || EnderecoRua.trim() === '') {
                    return res.status(400).json({ error: 'Rua é obrigatória para prestador' });
                }
                if (!EnderecoNumero || EnderecoNumero.trim() === '') {
                    return res.status(400).json({ error: 'Número é obrigatório para prestador' });
                }
                if (!EnderecoBairro || EnderecoBairro.trim() === '') {
                    return res.status(400).json({ error: 'Bairro é obrigatório para prestador' });
                }
                if (!EnderecoCidade || EnderecoCidade.trim() === '') {
                    return res.status(400).json({ error: 'Cidade é obrigatória para prestador' });
                }
                if (!EnderecoEstado || EnderecoEstado.trim() === '') {
                    return res.status(400).json({ error: 'Estado é obrigatório para prestador' });
                }
                if (!EnderecoCEP || EnderecoCEP.trim() === '') {
                    return res.status(400).json({ error: 'CEP é obrigatório para prestador' });
                }
            }

            if (tipo === 'EMPRESA') {
                if (!EmpresaCNPJ || EmpresaCNPJ.trim() === '') {
                    return res.status(400).json({ error: 'CNPJ é obrigatório para empresa' });
                }
            }

            // Verificar se usuário já existe (email ou telefone)
            const usuarioExistente = await prisma.usuario.findFirst({
                where: {
                    AND: [
                        {
                            OR: [
                                { UsuarioEmail: UsuarioEmail.trim() },
                                { UsuarioTelefone: UsuarioTelefone.trim() }
                            ]
                        },
                        {
                            UsuarioStatus: {
                                in: ['ATIVO', 'BLOQUEADO', 'BLOQUEADOPAGAMENTO']
                            }
                        }
                    ]
                },
            });

            if (usuarioExistente) {
                if (usuarioExistente.UsuarioEmail === UsuarioEmail.trim()) {
                    return res.status(409).json({ error: 'E-mail já cadastrado' });
                }
                if (usuarioExistente.UsuarioTelefone === UsuarioTelefone.trim()) {
                    return res.status(409).json({ error: 'Telefone já cadastrado' });
                }
            }

            let empresaExistente;

            if (tipo === 'EMPRESA') {
                empresaExistente = await prisma.empresa.findFirst({
                    where: {
                        AND: [
                            {
                                OR: [
                                    { EmpresaEmail: UsuarioEmail.trim() },
                                    { EmpresaTelefone: UsuarioTelefone.trim() },
                                    { EmpresaCNPJ: EmpresaCNPJ.trim() }
                                ]
                            },
                            {
                                EmpresaStatus: {
                                    in: ['ATIVA', 'BLOQUEADA', 'BLOQUEADAPAGAMENTO']
                                }
                            }
                        ]
                    },
                });
            } else {
                empresaExistente = await prisma.empresa.findFirst({
                    where: {
                        AND: [
                            {
                                OR: [
                                    { EmpresaEmail: UsuarioEmail.trim() },
                                    { EmpresaTelefone: UsuarioTelefone.trim() }
                                ]
                            },
                            {
                                EmpresaStatus: {
                                    in: ['ATIVA', 'BLOQUEADA', 'BLOQUEADAPAGAMENTO']
                                }
                            }
                        ]
                    },
                });
            }

            if (empresaExistente) {
                if (empresaExistente.EmpresaEmail === UsuarioEmail.trim()) {
                    return res.status(409).json({ error: 'E-mail já cadastrado' });
                }
                if (empresaExistente.EmpresaTelefone === UsuarioTelefone.trim()) {
                    return res.status(409).json({ error: 'Telefone já cadastrado' });
                }
                if (empresaExistente.EmpresaCNPJ === EmpresaCNPJ.trim()) {
                    return res.status(409).json({ error: 'CNPJ já cadastrado' });
                }
            }

            // Criptografar senha
            const saltRounds = 10;
            const hashedPassword = await bcrypt.hash(UsuarioSenha, saltRounds);

            // Criar usuário e endereço (se for prestador) em transação
            const result = await prisma.$transaction(async (prisma) => {
                // Criar endereço primeiro se for prestador
                let enderecoId = null;

                if (tipo !== 'EMPRESA') {
                    if (tipo === 'PRESTADOR') {
                        const endereco = await prisma.endereco.create({
                            data: {
                                UsuEstId: 0, // Será atualizado após criar o usuário
                                TipoRelacao: 'USUARIO',
                                EnderecoRua: EnderecoRua.trim(),
                                EnderecoNumero: EnderecoNumero.trim(),
                                EnderecoComplemento: EnderecoComplemento?.trim() || null,
                                EnderecoBairro: EnderecoBairro.trim(),
                                EnderecoCidade: EnderecoCidade.trim(),
                                EnderecoEstado: EnderecoEstado.trim().toUpperCase(),
                                EnderecoCEP: EnderecoCEP.trim()
                            }
                        });
                        enderecoId = endereco.EnderecoId;
                    }

                    // Criar usuário
                    const usuarioNovo = await prisma.usuario.create({
                        data: {
                            UsuarioNome: UsuarioNome.trim(),
                            UsuarioTelefone: UsuarioTelefone.trim(),
                            UsuarioEmail: UsuarioEmail.trim(),
                            UsuarioTipo: tipo,
                            UsuarioSenha: hashedPassword,
                            UsuarioEnderecoId: enderecoId
                        },
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true,
                            UsuarioTipo: true,
                            UsuarioEnderecoId: true
                        }
                    });

                    // Atualizar o UsuEstId do endereço com o ID do usuário
                    if (enderecoId) {
                        await prisma.endereco.update({
                            where: { EnderecoId: enderecoId },
                            data: { UsuEstId: usuarioNovo.UsuarioId }
                        });
                    }

                    return usuarioNovo;

                } else {
                    // Criar empresa
                    const empresaNova = await prisma.empresa.create({
                        data: {
                            EmpresaNome: UsuarioNome.trim(),
                            EmpresaCNPJ: EmpresaCNPJ.trim(),
                            EmpresaTelefone: UsuarioTelefone.trim(),
                            EmpresaEmail: UsuarioEmail.trim(),
                            EmpresaSenha: hashedPassword
                        },
                        select: {
                            EmpresaId: true,
                            EmpresaNome: true,
                            EmpresaCNPJ: true,
                            EmpresaTelefone: true,
                            EmpresaEmail: true
                        }
                    });

                    empresaNova.UsuarioTipo = tipo; // Adicionar tipo ao objeto de retorno para consistência

                    return empresaNova;
                }

            });

            res.status(201).json({
                message: 'Usuário criado com sucesso',
                data: result
            });
        } catch (error) {
            console.error('Erro ao cadastrar usuário:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Atualizar perfil (usuário ou empresa)
    async atualizarPerfil(req, res) {
        try {
            const perfilId = parseInt(req.params.id);
            const tipoPerfil = req.usuario.usuarioTipo; // Vem do token JWT

            // Verificar se o usuário logado é o dono do perfil
            if (req.usuario.usuarioId !== perfilId) {
                return res.status(403).json({
                    error: 'Você só pode alterar seu próprio perfil'
                });
            }

            const {
                // Campos comuns
                UsuarioNome,
                UsuarioTelefone,
                UsuarioEmail,
                UsuarioSenha,

                // Campos específicos para PRESTADOR
                EnderecoRua,
                EnderecoNumero,
                EnderecoComplemento,
                EnderecoBairro,
                EnderecoCidade,
                EnderecoEstado,
                EnderecoCEP,

                // Campos específicos para EMPRESA
                EmpresaCNPJ
            } = req.body;

            if (!perfilId) {
                return res.status(400).json({
                    error: 'Id é obrigatório.'
                });
            }

            // =============================================
            // CASO 1: EMPRESA
            // =============================================
            if (tipoPerfil === 'EMPRESA') {
                // Buscar empresa existente
                const empresa = await prisma.empresa.findUnique({
                    where: { EmpresaId: perfilId }
                });

                if (!empresa) {
                    return res.status(404).json({ error: 'Empresa não encontrada' });
                }

                // Verificar se email já está em uso por outra empresa
                if (UsuarioEmail && UsuarioEmail.trim() !== empresa.EmpresaEmail) {
                    const emailExistente = await prisma.empresa.findFirst({
                        where: {
                            EmpresaEmail: UsuarioEmail.trim(),
                            NOT: { EmpresaId: perfilId },
                            EmpresaStatus: { in: ['ATIVA', 'BLOQUEADA', 'BLOQUEADAPAGAMENTO'] }
                        }
                    });
                    if (emailExistente) {
                        return res.status(409).json({ error: 'E-mail já está em uso por outra empresa' });
                    }
                }

                // Verificar se telefone já está em uso por outra empresa
                if (UsuarioTelefone && UsuarioTelefone.trim() !== empresa.EmpresaTelefone) {
                    const telefoneExistente = await prisma.empresa.findFirst({
                        where: {
                            EmpresaTelefone: UsuarioTelefone.trim(),
                            NOT: { EmpresaId: perfilId },
                            EmpresaStatus: { in: ['ATIVA', 'BLOQUEADA', 'BLOQUEADAPAGAMENTO'] }
                        }
                    });
                    if (telefoneExistente) {
                        return res.status(409).json({ error: 'Telefone já está em uso por outra empresa' });
                    }
                }

                // Verificar se CNPJ já está em uso por outra empresa
                if (EmpresaCNPJ && EmpresaCNPJ.trim() !== empresa.EmpresaCNPJ) {
                    const cnpjExistente = await prisma.empresa.findFirst({
                        where: {
                            EmpresaCNPJ: EmpresaCNPJ.trim(),
                            NOT: { EmpresaId: perfilId },
                            EmpresaStatus: { in: ['ATIVA', 'BLOQUEADA', 'BLOQUEADAPAGAMENTO'] }
                        }
                    });
                    if (cnpjExistente) {
                        return res.status(409).json({ error: 'CNPJ já está em uso por outra empresa' });
                    }
                }

                // Criptografar nova senha se fornecida
                const saltRounds = 10;
                let hashedPassword = empresa.EmpresaSenha;
                if (UsuarioSenha && UsuarioSenha.trim() !== '') {
                    hashedPassword = await bcrypt.hash(UsuarioSenha, saltRounds);
                }

                // Atualizar empresa
                const empresaAtualizada = await prisma.empresa.update({
                    where: { EmpresaId: perfilId },
                    data: {
                        EmpresaNome: UsuarioNome ? UsuarioNome.trim() : empresa.EmpresaNome,
                        EmpresaTelefone: UsuarioTelefone ? UsuarioTelefone.trim() : empresa.EmpresaTelefone,
                        EmpresaEmail: UsuarioEmail ? UsuarioEmail.trim() : empresa.EmpresaEmail,
                        EmpresaCNPJ: EmpresaCNPJ ? EmpresaCNPJ.trim() : empresa.EmpresaCNPJ,
                        EmpresaSenha: hashedPassword
                    },
                    select: {
                        EmpresaId: true,
                        EmpresaNome: true,
                        EmpresaEmail: true,
                        EmpresaTelefone: true,
                        EmpresaCNPJ: true,
                        EmpresaStatus: true,
                        EmpresaDtCriacao: true
                    }
                });

                // Padronizar para o frontend
                const resultado = {
                    UsuarioId: empresaAtualizada.EmpresaId,
                    UsuarioNome: empresaAtualizada.EmpresaNome,
                    UsuarioEmail: empresaAtualizada.EmpresaEmail,
                    UsuarioTelefone: empresaAtualizada.EmpresaTelefone,
                    UsuarioTipo: 'EMPRESA',
                    UsuarioDtCriacao: empresaAtualizada.EmpresaDtCriacao,
                    UsuarioStatus: empresaAtualizada.EmpresaStatus,
                    EmpresaCNPJ: empresaAtualizada.EmpresaCNPJ
                };

                return res.status(200).json({
                    message: 'Perfil atualizado com sucesso',
                    data: resultado
                });
            }

            // =============================================
            // CASO 2: USUÁRIO (CLIENTE ou PRESTADOR)
            // =============================================

            // Buscar usuário existente
            const usuario = await prisma.usuario.findUnique({
                where: { UsuarioId: perfilId }
            });

            if (!usuario) {
                return res.status(404).json({ error: 'Usuário não encontrado' });
            }

            // Validações específicas para PRESTADOR (se estiver editando e for prestador)
            if (usuario.UsuarioTipo === 'PRESTADOR') {
                // Só validar se os campos estão sendo enviados para atualização
                if (UsuarioNome !== undefined && UsuarioNome.trim() === '') {
                    return res.status(400).json({ error: 'Nome não pode ser vazio' });
                }
                if (UsuarioTelefone !== undefined && UsuarioTelefone.trim() === '') {
                    return res.status(400).json({ error: 'Telefone não pode ser vazio' });
                }
                if (UsuarioEmail !== undefined && UsuarioEmail.trim() === '') {
                    return res.status(400).json({ error: 'E-mail não pode ser vazio' });
                }

                // Se algum campo de endereço foi enviado, validar todos os obrigatórios
                if (EnderecoRua !== undefined || EnderecoNumero !== undefined ||
                    EnderecoBairro !== undefined || EnderecoCidade !== undefined ||
                    EnderecoEstado !== undefined || EnderecoCEP !== undefined) {

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
                }
            }

            // Verificar se email já está em uso por outro usuário
            if (UsuarioEmail && UsuarioEmail.trim() !== usuario.UsuarioEmail) {
                const emailExistente = await prisma.usuario.findFirst({
                    where: {
                        UsuarioEmail: UsuarioEmail.trim(),
                        NOT: { UsuarioId: perfilId },
                        UsuarioStatus: { in: ['ATIVO', 'BLOQUEADO', 'BLOQUEADOPAGAMENTO'] }
                    }
                });
                if (emailExistente) {
                    return res.status(409).json({ error: 'E-mail já está em uso por outro usuário' });
                }
            }

            // Verificar se telefone já está em uso por outro usuário
            if (UsuarioTelefone && UsuarioTelefone.trim() !== usuario.UsuarioTelefone) {
                const telefoneExistente = await prisma.usuario.findFirst({
                    where: {
                        UsuarioTelefone: UsuarioTelefone.trim(),
                        NOT: { UsuarioId: perfilId },
                        UsuarioStatus: { in: ['ATIVO', 'BLOQUEADO', 'BLOQUEADOPAGAMENTO'] }
                    }
                });
                if (telefoneExistente) {
                    return res.status(409).json({ error: 'Telefone já está em uso por outro usuário' });
                }
            }

            // Verificar se email não está em uso por empresa
            if (UsuarioEmail && UsuarioEmail.trim() !== usuario.UsuarioEmail) {
                const emailEmpresa = await prisma.empresa.findFirst({
                    where: {
                        EmpresaEmail: UsuarioEmail.trim(),
                        EmpresaStatus: { in: ['ATIVA', 'BLOQUEADA', 'BLOQUEADAPAGAMENTO'] }
                    }
                });
                if (emailEmpresa) {
                    return res.status(409).json({ error: 'E-mail já está em uso por uma empresa' });
                }
            }

            // Verificar se telefone não está em uso por empresa
            if (UsuarioTelefone && UsuarioTelefone.trim() !== usuario.UsuarioTelefone) {
                const telefoneEmpresa = await prisma.empresa.findFirst({
                    where: {
                        EmpresaTelefone: UsuarioTelefone.trim(),
                        EmpresaStatus: { in: ['ATIVA', 'BLOQUEADA', 'BLOQUEADAPAGAMENTO'] }
                    }
                });
                if (telefoneEmpresa) {
                    return res.status(409).json({ error: 'Telefone já está em uso por uma empresa' });
                }
            }

            // Criptografar nova senha se fornecida
            const saltRounds = 10;
            let hashedPassword = usuario.UsuarioSenha;
            if (UsuarioSenha && UsuarioSenha.trim() !== '') {
                hashedPassword = await bcrypt.hash(UsuarioSenha, saltRounds);
            }

            // Atualizar em transação
            const resultado = await prisma.$transaction(async (prisma) => {
                // 1. Atualizar usuário
                const usuarioAtualizado = await prisma.usuario.update({
                    where: { UsuarioId: perfilId },
                    data: {
                        UsuarioNome: UsuarioNome ? UsuarioNome.trim() : usuario.UsuarioNome,
                        UsuarioTelefone: UsuarioTelefone ? UsuarioTelefone.trim() : usuario.UsuarioTelefone,
                        UsuarioEmail: UsuarioEmail ? UsuarioEmail.trim() : usuario.UsuarioEmail,
                        UsuarioSenha: hashedPassword
                    },
                    select: {
                        UsuarioId: true,
                        UsuarioNome: true,
                        UsuarioEmail: true,
                        UsuarioTelefone: true,
                        UsuarioTipo: true,
                        UsuarioEnderecoId: true,
                        UsuarioStatus: true,
                        UsuarioDtCriacao: true
                    }
                });

                // 2. Atualizar endereço se for prestador
                if (usuario.UsuarioTipo === 'PRESTADOR') {
                    // Verificar se algum campo de endereço foi enviado
                    const temEndereco = EnderecoRua || EnderecoNumero || EnderecoComplemento ||
                        EnderecoBairro || EnderecoCidade || EnderecoEstado || EnderecoCEP;

                    if (temEndereco) {
                        if (usuario.UsuarioEnderecoId) {
                            // Buscar endereço atual
                            const enderecoAtual = await prisma.endereco.findUnique({
                                where: { EnderecoId: usuario.UsuarioEnderecoId }
                            });

                            // Atualizar endereço existente
                            await prisma.endereco.update({
                                where: { EnderecoId: usuario.UsuarioEnderecoId },
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
                        } else if (EnderecoRua && EnderecoNumero && EnderecoBairro &&
                            EnderecoCidade && EnderecoEstado && EnderecoCEP) {
                            // Criar novo endereço
                            const novoEndereco = await prisma.endereco.create({
                                data: {
                                    UsuEstId: perfilId,
                                    TipoRelacao: 'USUARIO',
                                    EnderecoRua: EnderecoRua.trim(),
                                    EnderecoNumero: EnderecoNumero.trim(),
                                    EnderecoComplemento: EnderecoComplemento?.trim() || null,
                                    EnderecoBairro: EnderecoBairro.trim(),
                                    EnderecoCidade: EnderecoCidade.trim(),
                                    EnderecoEstado: EnderecoEstado.trim().toUpperCase(),
                                    EnderecoCEP: EnderecoCEP.trim()
                                }
                            });

                            // Vincular endereço ao usuário
                            await prisma.usuario.update({
                                where: { UsuarioId: perfilId },
                                data: { UsuarioEnderecoId: novoEndereco.EnderecoId }
                            });

                            usuarioAtualizado.UsuarioEnderecoId = novoEndereco.EnderecoId;
                        }
                    }
                }

                return usuarioAtualizado;
            });

            // Buscar endereço final para retornar
            let enderecoFinal = null;
            if (usuario.UsuarioTipo === 'PRESTADOR' && resultado.UsuarioEnderecoId) {
                enderecoFinal = await prisma.endereco.findUnique({
                    where: { EnderecoId: resultado.UsuarioEnderecoId }
                });
            }

            // Montar objeto de retorno
            const usuarioCompleto = {
                ...resultado,
                ...(enderecoFinal && {
                    EnderecoRua: enderecoFinal.EnderecoRua,
                    EnderecoNumero: enderecoFinal.EnderecoNumero,
                    EnderecoComplemento: enderecoFinal.EnderecoComplemento,
                    EnderecoBairro: enderecoFinal.EnderecoBairro,
                    EnderecoCidade: enderecoFinal.EnderecoCidade,
                    EnderecoEstado: enderecoFinal.EnderecoEstado,
                    EnderecoCEP: enderecoFinal.EnderecoCEP
                })
            };

            res.status(200).json({
                message: 'Perfil atualizado com sucesso',
                data: usuarioCompleto
            });

        } catch (error) {
            console.error('Erro ao atualizar perfil:', error);

            // Tratar erros específicos
            if (error.message && error.message.includes('já está em uso')) {
                return res.status(409).json({ error: error.message });
            }

            res.status(500).json({
                error: error.message
            });
        }
    }

    // Excluir usuário (apenas o próprio usuário pode excluir seu perfil)
    async excluirUsuario(req, res) {
        try {
            const usuarioId = parseInt(req.params.usuarioId);

            // Verificar se o usuário logado é o dono do perfil
            if (req.usuario.usuarioId !== usuarioId) {
                return res.status(403).json({
                    error: 'Você só pode excluir seu próprio perfil'
                });
            }

            let mensagemExclusao = 'Usuário excluído com sucesso';
            if (req.usuario.usuarioTipo === 'EMPRESA') {
                // Verificar se a empresa existe
                const empresa = await prisma.empresa.findUnique({
                    where: { EmpresaId: usuarioId }
                });

                if (!empresa) {
                    return res.status(404).json({ error: 'Empresa não encontrada' });
                }

                // Executar todas as operações em uma transação
                await prisma.$transaction(async (prisma) => {
                    // 1. Obtendo os estabelecimentos da empresa
                    const estabelecimentos = await prisma.estabelecimento.findMany({
                        where: { EmpresaId: usuarioId }
                    });

                    const estabelecimentoIds = estabelecimentos.map(est => est.EstabelecimentoId);

                    // 2. Excluindo os vínculos de usuários com os estabelecimentos
                    if (estabelecimentoIds.length > 0) {
                        await prisma.usuarioEstabelecimento.update({
                            where: { EstabelecimentoId: { in: estabelecimentoIds } },
                            data: { UsuarioEstabelecimentoStatus: 'EXCLUIDO' }
                        });
                    }

                    // 3. Excluindo os endereços dos estabelecimentos
                    const enderecoIds = estabelecimentos
                        .map(est => est.EstabelecimentoEndereco)
                        .filter(id => id != null);

                    if (enderecoIds.length > 0) {
                        await prisma.endereco.deleteMany({
                            where: { EnderecoId: { in: enderecoIds } }
                        });
                    }

                    // 4. Obtendo os serviços dos estabelecimentos da empresa
                    let servicos = [];
                    if (estabelecimentoIds.length > 0) {
                        servicos = await prisma.servico.findMany({
                            where: {
                                OR: [
                                    { EstabelecimentoId: { in: estabelecimentoIds } },
                                    { ServicoEstabelecimentoId: { in: estabelecimentoIds } }
                                ]
                            }
                        });
                    }

                    // 5. Desativando os serviços dos prestadores vinculados aos estabelecimentos da empresa
                    const servicoEstabelecimentoIds = servicos
                        .map(s => s.ServicoEstabelecimentoId)
                        .filter(id => id != null);

                    if (servicoEstabelecimentoIds.length > 0) {
                        await prisma.servico.updateMany({
                            where: { ServicoEstabelecimentoId: { in: servicoEstabelecimentoIds } },
                            data: { ServicoAtivo: false }
                        });
                    }

                    // 6. Desativando os serviços dos estabelecimentos da empresa
                    if (estabelecimentoIds.length > 0) {
                        await prisma.servico.updateMany({
                            where: { EstabelecimentoId: { in: estabelecimentoIds } },
                            data: { ServicoAtivo: false }
                        });
                    }

                    // 7. Recusando os agendamentos futuros dos estabelecimentos da empresa
                    if (estabelecimentoIds.length > 0) {
                        await prisma.agendamento.updateMany({
                            where: { EstabelecimentoId: { in: estabelecimentoIds } },
                            data: {
                                AgendamentoStatus: 'RECUSADO',
                                AgendamentoDescricaoTrabalho: 'Agendamento recusado devido à exclusão da empresa'
                            }
                        });
                    }

                    // 8. Desativando os estabelecimentos da empresa
                    if (estabelecimentoIds.length > 0) {
                        await prisma.estabelecimento.updateMany({
                            where: { EmpresaId: usuarioId },
                            data: { EstabelecimentoStatus: 'EXCLUIDO' }
                        });
                    }

                    // 9. Excluir empresa (soft delete - marcar como excluída)
                    await prisma.empresa.update({
                        where: { EmpresaId: usuarioId },
                        data: { EmpresaStatus: 'EXCLUIDA' }
                    });
                });

                mensagemExclusao = 'Empresa excluída com sucesso';
            } else {
                // Verificar se usuário existe
                const usuario = await prisma.usuario.findUnique({
                    where: { UsuarioId: usuarioId }
                });

                if (!usuario) {
                    return res.status(404).json({ error: 'Usuário não encontrado' });
                }

                // Executar todas as operações em uma transação
                await prisma.$transaction(async (prisma) => {
                    // 1. Excluindo o endereço do usuário se for prestador
                    if (usuario.UsuarioTipo === 'PRESTADOR' && usuario.UsuarioEnderecoId) {
                        await prisma.endereco.delete({
                            where: { EnderecoId: usuario.UsuarioEnderecoId }
                        });
                    }

                    // 2. Recusando os agendamentos futuros do usuário como prestador
                    await prisma.agendamento.updateMany({
                        where: { PrestadorId: usuarioId },
                        data: {
                            AgendamentoStatus: 'RECUSADO',
                            AgendamentoDescricaoTrabalho: 'Agendamento recusado devido à exclusão do prestador'
                        }
                    });

                    // 3. Recusando os agendamentos futuros do usuário como cliente
                    await prisma.agendamento.updateMany({
                        where: { ClienteId: usuarioId },
                        data: {
                            AgendamentoStatus: 'CANCELADO',
                            AgendamentoDescricaoTrabalho: 'Agendamento cancelado devido à exclusão do cliente'
                        }
                    });

                    // 4. Retirando o usuário dos estabelecimentos que ele estava vinculado
                    await prisma.usuarioEstabelecimento.update({
                        where: { UsuarioId: usuarioId },
                        data: { UsuarioEstabelecimentoStatus: 'EXCLUIDO' }
                    });

                    // 5. Desativando os serviços dos prestadores vinculados aos estabelecimentos da empresa
                    await prisma.servico.updateMany({
                        where: { PrestadorId: usuarioId },
                        data: { ServicoAtivo: false }
                    });

                    // 6. Excluir usuário (soft delete - marcar como excluído)
                    await prisma.usuario.update({
                        where: {
                            UsuarioId: usuarioId
                        },
                        data: {
                            UsuarioStatus: 'EXCLUIDO'
                        }
                    });
                });
            }

            res.status(200).json({
                message: mensagemExclusao
            });
        } catch (error) {
            console.error('Erro ao excluir usuário:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // Rota que registra o logout do usuário (apenas para clientes e prestadores)
    async logout(req, res) {
        try {
            const usuarioId = req.usuario.usuarioId;

            const usuarioTipo = req.usuario.usuarioTipo;

            if (usuarioTipo !== 'CLIENTE' && usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Tipo de usuário inválido para logout'
                });
            }

            // Adiocnar registro na tabela log
            await prisma.log.create({
                data: {
                    UsuEmpId: usuarioId,
                    LogAcao: 'LOGOUT',
                    TipoRelacao: 'USUARIO',
                    LogDetalhe: 'Usuário realizou logout',
                    LogData: new Date()
                }
            });

            res.status(200).json({
                message: 'Logout realizado com sucesso'
            });

        } catch (error) {
            console.error('Erro ao buscar usuário:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

}

module.exports = new UsuarioController();