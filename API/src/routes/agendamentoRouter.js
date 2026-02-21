// src/routes/agendamentoRoutes.js
const express = require('express');
const agendamentoController = require('../controllers/agendamentoController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Todas as rotas de agendamento exigem autenticação (usuário logado)
router.use(authMiddleware);

// Rotas específicas por tipo de usuário
router.get('/meus-cliente', agendamentoController.listarMeusAgendamentosCliente);
router.get('/meus-prestador', agendamentoController.listarMeusAgendamentosPrestador);
router.get('/periodo', agendamentoController.listarAgendamentosPorPeriodo);

// Rotas de manipulação
router.post('/', agendamentoController.cadastrarAgendamento); // Apenas CLIENTE
router.put('/:id/status', agendamentoController.atualizarStatus); // Cliente ou Prestador
router.patch('/:agendamentoId/cancelar', agendamentoController.cancelarAgendamento); // Cliente ou Prestador

// Rota de consulta por ID (protegida - apenas envolvidos)
router.get('/:agendamentoId', agendamentoController.buscarAgendamentoId);

module.exports = router;