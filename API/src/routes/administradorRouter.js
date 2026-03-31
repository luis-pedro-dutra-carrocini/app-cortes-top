// src/routes/agendamentoRouter.js
const express = require('express');
const administradorController = require('../controllers/administradorController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Rotas públicas (não precisam de autenticação)
router.post('/login', administradorController.login);

// Todas as rotas de agendamento exigem autenticação (usuário logado)
router.use(authMiddleware);

module.exports = router;