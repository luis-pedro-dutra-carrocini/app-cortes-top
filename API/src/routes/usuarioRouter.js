// src/routes/usuarioRoutes.js
const express = require('express');
const usuarioController = require('../controllers/usuarioController');
const authMiddleware = require('../middlewares/authMiddleware');
const { usuario } = require('../prisma');

const router = express.Router();

// Rotas públicas (não precisam de autenticação)
router.post('/login', usuarioController.login);
router.post('/cadastrar', usuarioController.cadastrarUsuario);
router.post('/login/google', usuarioController.loginGoogle);

// Rota para validar token - pode ser usada para verificar se o usuário está autenticado
router.get('/validar-token', authMiddleware, usuarioController.validarUsuario);

// Rota de busca por ID - pode ser pública ou restrita dependendo da sua regra de negócio
// Se quiser que seja pública, remova o middleware
router.get('/:usuarioId', authMiddleware, usuarioController.buscarUsuarioId);

router.post('/logout', authMiddleware, usuarioController.logout);

// Listar últimos prestadores do cliente (apenas CLIENTE)
router.get('/prestadores/ultimos', authMiddleware, usuarioController.listarUltimosPrestadoresCliente);

// Pesquisar prestadores (qualquer usuário logado)
router.get('/prestadores/pesquisa', authMiddleware, usuarioController.pesquisarPrestadores);

// Rotas protegidas (precisam de autenticação)
router.put('/:id', authMiddleware, usuarioController.atualizarPerfil);
router.delete('/:usuarioId', authMiddleware, usuarioController.excluirUsuario);

module.exports = router;