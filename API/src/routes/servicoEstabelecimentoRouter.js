const express = require('express');
const servicoEstabelecimentoController = require('../controllers/servicoEstabelecimentoController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Todas as rotas exigem autenticação
router.use(authMiddleware);

router.get('/prestador/:prestadorId/estabelecimento/:estabelecimentoId', servicoEstabelecimentoController.listarServicosPrestadorPorEstabelecimento);

// Rotas para serviços do estabelecimento (EMPRESA)
router.post('/', servicoEstabelecimentoController.cadastrarServicoEstabelecimento);
router.get('/estabelecimento/:estabelecimentoId', servicoEstabelecimentoController.listarServicosPorEstabelecimento);
router.get('/estabelecimento/:estabelecimentoId/todos', servicoEstabelecimentoController.listarTodosServicosPorEstabelecimento);
router.get('/:servicoEstabelecimentoId', servicoEstabelecimentoController.buscarServicoEstabelecimentoId);
router.put('/:id', servicoEstabelecimentoController.atualizarServicoEstabelecimento);

// Rotas para vínculo com prestadores
router.get('/:servicoEstabelecimentoId/prestadores-disponiveis', servicoEstabelecimentoController.listarPrestadoresDisponiveisParaServico);
router.get('/:servicoEstabelecimentoId/prestadores-vinculados', servicoEstabelecimentoController.listarPrestadoresVinculados);
router.post('/:servicoEstabelecimentoId/vincular/:prestadorId', servicoEstabelecimentoController.vincularServicoAPrestador);
router.delete('/vincular/:servicoId', servicoEstabelecimentoController.desvincularServicoDePrestador);

module.exports = router;