// src/controllers/usuarioController.js
const prisma = require('../prisma.js');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

class UsuarioController {

    // Login do usuário
    async login(req, res) {
        try {
            const { UsuarioEmail, UsuarioSenha } = req.body;

            if (!UsuarioEmail || !UsuarioSenha) {
                return res.status(400).json({ 
                    error: 'E-mail e senha são obrigatórios' 
                });
            }

            // Buscar usuário pelo email
            const usuario = await prisma.usuario.findFirst({
                where: { UsuarioEmail: UsuarioEmail.trim() }
            });

            if (!usuario) {
                return res.status(401).json({ 
                    error: 'E-mail ou senha inválidos' 
                });
            }

            // Verificar senha
            const senhaValida = await bcrypt.compare(UsuarioSenha, usuario.UsuarioSenha);

            if (!senhaValida) {
                return res.status(401).json({ 
                    error: 'E-mail ou senha inválidos' 
                });
            }

            // Gerar token JWT
            const token = jwt.sign(
                { 
                    usuarioId: usuario.UsuarioId,
                    usuarioTipo: usuario.UsuarioTipo,
                    usuarioEmail: usuario.UsuarioEmail
                },
                process.env.JWT_SECRET,
                { expiresIn: '24h' }
            );

            // Remover senha do objeto de retorno
            const { UsuarioSenha: _, ...usuarioSemSenha } = usuario;

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

    // Buscar Usuário por ID (qualquer usuário logado pode ver qualquer perfil)
    async buscarUsuarioId(req, res) {
        try {
            const { usuarioId } = req.params;

            const usuario = await prisma.usuario.findFirst({
                where: {
                    UsuarioId: parseInt(usuarioId)
                },
                select: {
                    UsuarioId: true,
                    UsuarioNome: true,
                    UsuarioTelefone: true,
                    UsuarioEmail: true,
                    UsuarioTipo: true,
                }
            });

            if (!usuario) {
                return res.status(404).json({ error: 'Usuário não encontrado' });
            }

            res.status(200).json({ data: usuario });

        } catch (error) {
            console.error('Erro ao buscar usuário:', error);
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
                UsuarioTipo
            } = req.body;

            // Validações
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
            } else if (!['CLIENTE', 'PRESTADOR'].includes(UsuarioTipo.trim().toUpperCase())) {
                return res.status(400).json({ error: 'Tipo de usuário inválido. Deve ser "CLIENTE" ou "PRESTADOR"' });
            }

            // Verificar se usuário já existe (email ou telefone)
            const usuarioExistente = await prisma.usuario.findFirst({
                where: {
                    UsuarioEmail: UsuarioEmail.trim()
                },
            });

            if (usuarioExistente) {
                return res.status(409).json({ error: 'Usuário já cadastrado com este e-mail' });
            }

            // Criptografar senha
            const saltRounds = 10;
            const hashedPassword = await bcrypt.hash(UsuarioSenha, saltRounds);

            // Criar usuário
            const usuarioNovo = await prisma.usuario.create({
                data: {
                    UsuarioNome: UsuarioNome.trim(),
                    UsuarioTelefone: UsuarioTelefone.trim(),
                    UsuarioEmail: UsuarioEmail.trim(),
                    UsuarioTipo: UsuarioTipo.trim().toUpperCase(),
                    UsuarioSenha: hashedPassword
                },
                select: {
                    UsuarioId: true,
                    UsuarioNome: true,
                    UsuarioEmail: true,
                    UsuarioTelefone: true,
                    UsuarioTipo: true
                }
            });

            res.status(201).json({
                message: 'Usuário criado com sucesso',
                data: usuarioNovo
            });
        } catch (error) {
            console.error('Erro ao cadastrar usuário:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Atualizar usuário (apenas o próprio usuário pode alterar seu perfil)
    async atualizarUsuario(req, res) {
        try {
            const usuarioId = parseInt(req.params.id);

            // Verificar se o usuário logado é o dono do perfil
            if (req.usuario.usuarioId !== usuarioId) {
                return res.status(403).json({ 
                    error: 'Você só pode alterar seu próprio perfil' 
                });
            }

            const {
                UsuarioNome,
                UsuarioTelefone,
                UsuarioEmail,
                UsuarioSenha
            } = req.body;

            if (!usuarioId) {
                return res.status(400).json({
                    error: 'Id é obrigatório.'
                });
            }

            // Buscar usuário existente
            const usuario = await prisma.usuario.findUnique({
                where: { UsuarioId: usuarioId },
            });

            if (!usuario) {
                return res.status(404).json({ error: 'Usuário não encontrado' });
            }

            // Verificar se email já está em uso por outro usuário
            if (UsuarioEmail && UsuarioEmail.trim() !== usuario.UsuarioEmail) {
                const emailExistente = await prisma.usuario.findFirst({
                    where: { AND: { UsuarioEmail: UsuarioEmail.trim() }}
                });
                if (emailExistente) {
                    return res.status(409).json({ error: 'E-mail já está em uso por outro usuário' });
                }
            }

            // Criptografar nova senha se fornecida
            const saltRounds = 10;
            let hashedPassword = usuario.UsuarioSenha;
            if (UsuarioSenha && UsuarioSenha.trim() !== '') {
                hashedPassword = await bcrypt.hash(UsuarioSenha, saltRounds);
            }

            // Atualizar usuário
            const usuarioAtualizado = await prisma.usuario.update({
                where: {
                    UsuarioId: usuarioId
                },
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
                    UsuarioTipo: true
                }
            });

            res.status(200).json({
                message: 'Usuário atualizado com sucesso',
                data: usuarioAtualizado
            });

        } catch (error) {
            console.error('Erro ao atualizar usuário:', error);
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

            // Verificar se usuário existe
            const usuario = await prisma.usuario.findUnique({
                where: { UsuarioId: usuarioId }
            });

            if (!usuario) {
                return res.status(404).json({ error: 'Usuário não encontrado' });
            }

            // Excluir usuário
            await prisma.usuario.delete({
                where: {
                    UsuarioId: usuarioId
                }
            });

            res.status(200).json({
                message: 'Usuário excluído com sucesso'
            });
        } catch (error) {
            console.error('Erro ao excluir usuário:', error);
            res.status(500).json({ error: error.message });
        }
    }
}

module.exports = new UsuarioController();