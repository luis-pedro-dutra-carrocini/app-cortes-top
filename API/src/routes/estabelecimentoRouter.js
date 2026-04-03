// src/routes/estabelecimentoRouter.js
const express = require('express');
const estabelecimentoController = require('../controllers/estabelecimentoController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Todas as rotas de estabelecimento exigem autenticação
router.use(authMiddleware);

// Rotas principais de estabelecimento (apenas EMPRESA)
router.post('/', estabelecimentoController.criarEstabelecimento);
router.get('/', estabelecimentoController.listarEstabelecimentos);
router.get('/:estabelecimentoId', estabelecimentoController.buscarEstabelecimentoPorId);
router.put('/:id', estabelecimentoController.atualizarEstabelecimento);
router.patch('/:estabelecimentoId/status', estabelecimentoController.alternarStatusEstabelecimento);

// Rotas de vinculo
router.get('/:estabelecimentoId/vinculos', estabelecimentoController.listarVinculos);
router.post('/:estabelecimentoId/solicitar-vinculo/:usuarioId', estabelecimentoController.solicitarVinculo);
router.get('/:estabelecimentoId/prestadores-disponiveis', estabelecimentoController.listarPrestadoresDisponiveis);

// Rotas de vínculo (baseadas no ID do vínculo)
router.patch('/vinculos/:vinculoId/aceitar', estabelecimentoController.aceitarVinculo);
router.patch('/vinculos/:vinculoId/recusar', estabelecimentoController.recusarVinculo);
router.patch('/vinculos/:vinculoId/desativar', estabelecimentoController.desativarVinculo);
router.patch('/vinculos/:vinculoId/reativar', estabelecimentoController.reativarVinculo);
router.delete('/vinculos/:vinculoId', estabelecimentoController.excluirVinculo);

// Rotas de vínculo de usuários
router.post('/:estabelecimentoId/usuarios/:usuarioId', estabelecimentoController.vincularUsuario);
router.delete('/:estabelecimentoId/usuarios/:usuarioId', estabelecimentoController.desvincularUsuario);
router.get('/:estabelecimentoId/usuarios', estabelecimentoController.listarUsuariosVinculados);
router.get('/:estabelecimentoId/prestadores-disponiveis', estabelecimentoController.listarPrestadoresDisponiveis);

// Pretador vê seus vinculos com estabelcimentos
router.get('/prestador/vinculos/todos', estabelecimentoController.listarVinculosPrestador);

module.exports = router;