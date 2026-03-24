// server.js
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');

const app = express();

// Middleware para cookies
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// API Routes
const agendamentoRouter = require('./routes/agendamentoRouter');
const disponibilidadeRouter = require('./routes/disponibilidadeRouter');
const servicoPrecoRouter = require('./routes/servicoPrecoRouter');
const servicoRouter = require('./routes/servicoRouter');
const usuarioRouter = require('./routes/usuarioRouter');
const dashboardRouter = require('./routes/dashboardRouter');
const estabelecimentoRouter = require('./routes/estabelecimentoRouter');
const servicoEstabelecimentoRouter = require('./routes/servicoEstabelecimentoRouter');
const empresaRouter = require('./routes/empresaRouter');
const pesquisaRoutes = require('./routes/pesquisaRoutes');
const dashboardEmpresaRoutes = require('./routes/dashboardEmpresaRouter');

app.use('/api/agendamento', agendamentoRouter);
app.use('/api/disponibilidade', disponibilidadeRouter);
app.use('/api/servicoPreco', servicoPrecoRouter);
app.use('/api/servico', servicoRouter);
app.use('/api/usuario', usuarioRouter);
app.use('/api/dashboard', dashboardRouter);
app.use('/api/estabelecimento', estabelecimentoRouter);
app.use('/api/servicoEstabelecimento', servicoEstabelecimentoRouter);
app.use('/api/empresa', empresaRouter);
app.use('/api/pesquisa', pesquisaRoutes);
app.use('/api/dashboard-empresa', dashboardEmpresaRoutes);

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`📖 Servidor rodando na porta ${PORT}`);
});