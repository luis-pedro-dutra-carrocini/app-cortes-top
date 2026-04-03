// src/controllers/administradorController.js
const prisma = require('../prisma.js');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

class UsuarioController {

    // Login do administrador
    async login(req, res) {
        try {
            const { AdministradorUsuario, AdministradorSenha } = req.body;

            if (!AdministradorUsuario || !AdministradorSenha) {
                return res.status(400).json({
                    error: 'Usuário e senha são obrigatórios'
                });
            }

            let usuarioSemSenha = null;
            let token = null;

            // Buscar na tabela Administrador
            let administrador = await prisma.administrador.findFirst({
                where: {
                    AdministradorUsuario: AdministradorUsuario.trim().toUpperCase()
                }
            });

            if (!administrador) {
                return res.status(403).json({
                    error: 'Usuário ou senha inválidos'
                });
            }

            // Verificar senha
            // Verificar senha (aplicando o pepper antes de comparar)
            const senhaComPepper = process.env.PEPPER_SENHA_ADMIN + AdministradorSenha.trim();
            const senhaValida = await bcrypt.compare(senhaComPepper, administrador.AdministradorSenha);

            if (!senhaValida) {
                return res.status(403).json({
                    error: 'Usuário ou senha inválidos'
                });
            }

            // Gerar token JWT
            token = jwt.sign(
                {
                    administradorId: administrador.AdministradorId,
                    administradorsuario: administrador.AdministradorUsuario
                },
                process.env.JWT_SECRET,
                { expiresIn: '24h' }
            );

            // Adaptar para o formato esperado pelo frontend (similar a Usuario)
            usuarioSemSenha = {
                AdministradorId: administrador.AdministradorId,
                AdministradorUsuario: administrador.AdministradorUsuario
            };

            // Atualizar último login
            const dataLocal = new Date();

            // Ajusta para o fuso de Brasília (UTC -3)
            const dataBrasilia = new Date(dataLocal.getTime() - (3 * 60 * 60 * 1000));
            
            await prisma.administrador.update({
                where: { AdministradorId: administrador.AdministradorId },
                data: { AdministradorUltimoLogin: dataBrasilia }
            });

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

    

}

module.exports = new UsuarioController();