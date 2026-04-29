// server.js
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const cors = require('cors');
require('dotenv').config();

const app = express();

const allowedOrigins = [process.env.CORS_ORIGIN];
//console.log('CORS_ORIGIN:', process.env.CORS_ORIGIN);

const corsOptions = {
    origin: allowedOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'], // Inclua OPTIONS
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    exposedHeaders: ['Content-Range', 'X-Content-Range'],
    preflightContinue: false,
    optionsSuccessStatus: 204
};

app.use(cors(corsOptions));

// Middleware para cookies
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const PORT = process.env.PORT;

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
const pesquisaRouter = require('./routes/pesquisaRouter');
const dashboardEmpresaRouter = require('./routes/dashboardEmpresaRouter');
const administradorRouter = require('./routes/administradorRouter');

app.use('/api/agendamento', agendamentoRouter);
app.use('/api/disponibilidade', disponibilidadeRouter);
app.use('/api/servicoPreco', servicoPrecoRouter);
app.use('/api/servico', servicoRouter);
app.use('/api/usuario', usuarioRouter);
app.use('/api/dashboard', dashboardRouter);
app.use('/api/estabelecimento', estabelecimentoRouter);
app.use('/api/servicoEstabelecimento', servicoEstabelecimentoRouter);
app.use('/api/empresa', empresaRouter);
app.use('/api/pesquisa', pesquisaRouter);
app.use('/api/dashboard-empresa', dashboardEmpresaRouter);
app.use('/api/admin', administradorRouter);

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`📖 Servidor rodando na porta ${PORT}`);
});