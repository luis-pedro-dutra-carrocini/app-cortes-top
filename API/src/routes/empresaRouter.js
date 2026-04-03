// src/routes/empresaRouter.js
const express = require('express');
const empresaController = require('../controllers/empresaController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Todas as rotas de empresa exigem autenticação (usuário logado)
router.use(authMiddleware);

router.get('/busca', empresaController.buscarEmpresas);
router.get('/:empresaId/estabelecimentos', empresaController.buscarEstabelecimentosPorEmpresa);
router.get('/estabelecimento/:estabelecimentoId/prestadores', empresaController.buscarPrestadoresPorEstabelecimento);

module.exports = router;