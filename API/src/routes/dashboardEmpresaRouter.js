const express = require('express');
const dashboardEmpresaController = require('../controllers/dashboardEmpresaController');
const authMiddleware = require('../middlewares/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

router.get('/', dashboardEmpresaController.obterDashboardEmpresa);
router.get('/resumo', dashboardEmpresaController.obterResumoRapidoEmpresa);

module.exports = router;