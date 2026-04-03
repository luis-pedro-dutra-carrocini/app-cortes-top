// src/routes/servicoPrecoRoutes.js
const express = require('express');
const servicoPrecoController = require('../controllers/servicoPrecoController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Todas as rotas de preço exigem autenticação (usuário logado)
router.use(authMiddleware);

// Rotas de consulta (qualquer usuário logado pode acessar)
router.get('/servico/:servicoId', servicoPrecoController.listarPrecosPorServico);
router.get('/servico/:servicoId/atual', servicoPrecoController.buscarPrecoAtual);
router.get('/:precoId', servicoPrecoController.buscarPrecoId);

// Rota de criação (apenas PRESTADOR dono do serviço)
router.post('/servico/:servicoId', servicoPrecoController.adicionarPreco);

// Rota para empresa atualizar preço de todos os prestadores vinculados a um serviço do estabelecimento
router.post('/servico-estabelecimento/:servicoEstabelecimentoId/preco-unificado', servicoPrecoController.atualizarPrecoServicoEstabelecimento);

// NOTA: Não há rotas para update (PUT/PATCH) ou delete
// Isso garante que o histórico não possa ser alterado ou excluído

module.exports = router;