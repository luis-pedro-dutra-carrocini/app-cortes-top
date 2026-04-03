// src/routes/dashboardRouter.js
const express = require('express');
const dashboardController = require('../controllers/dashboardController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

// Todas as rotas de dashboard exigem autenticação
router.use(authMiddleware);

// Rotas específicas para prestadores
router.get('/', dashboardController.obterDashboard);
router.get('/resumo-rapido', dashboardController.obterResumoRapido);

module.exports = router;