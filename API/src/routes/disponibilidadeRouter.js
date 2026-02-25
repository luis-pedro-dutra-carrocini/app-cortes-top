// src/routes/disponibilidadeRoutes.js
const express = require('express');
const disponibilidadeController = require('../controllers/disponibilidadeController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Todas as rotas de disponibilidade exigem autenticação (usuário logado)
router.use(authMiddleware);

// Rotas de consulta (qualquer usuário logado pode acessar)
router.get('/prestador/:prestadorId/data/:data', disponibilidadeController.listarDisponibilidadesPorPrestadorData);
router.get('/dia/:data', disponibilidadeController.buscarDisponibilidadesPorData);
router.get('/:disponibilidadeId', disponibilidadeController.buscarDisponibilidadeId);

// Rotas de manipulação (apenas PRESTADOR e dono da disponibilidade)
router.get('/prestador/:prestadorId', disponibilidadeController.listarDisponibilidadesPorPrestador);
router.post('/', disponibilidadeController.cadastrarDisponibilidade);
router.put('/:id', disponibilidadeController.atualizarDisponibilidade);
router.delete('/:disponibilidadeId', disponibilidadeController.excluirDisponibilidade);

module.exports = router;