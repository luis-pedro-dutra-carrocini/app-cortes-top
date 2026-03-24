const express = require('express');
const pesquisaController = require('../controllers/pesquisaController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Todas as rotas de pesquisa exigem autenticação
router.use(authMiddleware);

// Rotas de pesquisa
router.get('/prestadores', pesquisaController.pesquisarPrestadores);
router.get('/empresas', pesquisaController.pesquisarEmpresas);
router.get('/estabelecimentos', pesquisaController.pesquisarEstabelecimentos);
router.get('/todos', pesquisaController.pesquisarTodos);

module.exports = router;