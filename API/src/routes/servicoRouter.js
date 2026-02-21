// src/routes/servicoRoutes.js
const express = require('express');
const servicoController = require('../controllers/servicoController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Todas as rotas de serviço exigem autenticação (usuário logado)
router.use(authMiddleware);

// Rotas de consulta (qualquer usuário logado pode acessar)
router.get('/prestador/:prestadorId', servicoController.listarServicosPorPrestador);
router.get('/:servicoId', servicoController.buscarServicoId);

// Rota para listar todos os serviços de um prestador, incluindo inativos (apenas o dono dos serviços)
router.get('/prestador/:prestadorId/todos', servicoController.listarTodosServicosPorPrestador);

// Rotas de manipulação (apenas PRESTADOR e dono do serviço)
router.post('/', servicoController.cadastrarServico);
router.put('/:id', servicoController.atualizarServico);
router.patch('/:servicoId/status', servicoController.alternarStatusServico);
router.delete('/:servicoId', servicoController.excluirServico);

module.exports = router;