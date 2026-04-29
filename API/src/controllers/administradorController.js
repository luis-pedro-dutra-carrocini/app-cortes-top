// src/controllers/administradorController.js
const { UsuarioStatus } = require('@prisma/client');
const prisma = require('../prisma.js');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// 1. Últimos logins de empresas e usuários
async function getUltimosLogins() {
    const ultimosLogins = [];

    // Últimos logins de empresas
    const empresas = await prisma.empresa.findMany({
        where: {
            EmpresaUltimoLogin: {
                not: null
            }
        },
        select: {
            EmpresaId: true,
            EmpresaNome: true,
            EmpresaUltimoLogin: true,
            EmpresaStatus: true,
            EmpresaEmail: true
        },
        orderBy: {
            EmpresaUltimoLogin: 'desc'
        },
        take: 10
    });

    empresas.forEach(empresa => {
        ultimosLogins.push({
            tipo: 'EMPRESA',
            id: empresa.EmpresaId,
            nome: empresa.EmpresaNome,
            ultimoLogin: empresa.EmpresaUltimoLogin,
            status: empresa.EmpresaStatus,
            inativo: calcularInatividade(empresa.EmpresaUltimoLogin),
            email: empresa.EmpresaEmail
        });
    });

    // Últimos logins de usuários
    const usuarios = await prisma.usuario.findMany({
        where: {
            UsuarioUltimoLogin: {
                not: null
            }
        },
        select: {
            UsuarioId: true,
            UsuarioNome: true,
            UsuarioUltimoLogin: true,
            UsuarioStatus: true,
            UsuarioTipo: true,
            UsuarioEmail: true
        },
        orderBy: {
            UsuarioUltimoLogin: 'desc'
        },
        take: 10
    });

    usuarios.forEach(usuario => {
        ultimosLogins.push({
            tipo: usuario.UsuarioTipo,
            id: usuario.UsuarioId,
            nome: usuario.UsuarioNome,
            ultimoLogin: usuario.UsuarioUltimoLogin,
            status: usuario.UsuarioStatus,
            inativo: calcularInatividade(usuario.UsuarioUltimoLogin),
            email: usuario.UsuarioEmail
        });
    });

    // Ordenar por data mais recente
    ultimosLogins.sort((a, b) => new Date(b.ultimoLogin) - new Date(a.ultimoLogin));

    return ultimosLogins.slice(0, 20);
}

// 2. Últimas saídas/entradas dos usuários
async function getUltimasEntradasSaidas() {
    const logs = await prisma.log.findMany({
        where: {
            LogAcao: {
                in: ['LOGIN', 'LOGOUT', 'LOGIN_GOOGLE', 'ENTRADA_DIRETA']
            }
        },
        select: {
            LogId: true,
            LogAcao: true,
            LogDetalhe: true,
            LogData: true,
            UsuEmpId: true,
            TipoRelacao: true
        },
        orderBy: {
            LogData: 'desc'
        },
        take: 15
    });

    const resultado = [];

    for (const log of logs) {
        let nome = '';
        let email = '';

        if (log.TipoRelacao === 'USUARIO' && log.UsuEmpId) {
            const usuario = await prisma.usuario.findUnique({
                where: { UsuarioId: log.UsuEmpId },
                select: { UsuarioNome: true, UsuarioTipo: true, UsuarioEmail: true }
            });
            if (usuario) {
                nome = `${usuario.UsuarioNome} (${usuario.UsuarioTipo})`;
                email = usuario.UsuarioEmail;
            }
        } else if (log.TipoRelacao === 'EMPRESA' && log.UsuEmpId) {
            const empresa = await prisma.empresa.findUnique({
                where: { EmpresaId: log.UsuEmpId },
                select: { EmpresaNome: true, EmpresaEmail: true }
            });
            if (empresa) {
                nome = `${empresa.EmpresaNome} (EMPRESA)`;
                email = empresa.EmpresaEmail;
            }
        }

        let logdetalhe = log.LogDetalhe ? log.LogDetalhe.trim() : '';
        logdetalhe = logdetalhe.substring(0, 30); // Limitar a 30 caracteres
        logdetalhe += '...'; // Indicar que foi truncado

        resultado.push({
            acao: log.LogAcao,
            nome: nome || 'Desconhecido',
            tipoRelacao: log.TipoRelacao,
            data: log.LogData,
            detalhe: logdetalhe,
            email: email
        });
    }

    return resultado;
}

// 3. Últimos usuários cadastrados
async function getUltimosCadastros() {
    const cadastros = [];

    // Últimas empresas cadastradas
    const empresas = await prisma.empresa.findMany({
        select: {
            EmpresaId: true,
            EmpresaNome: true,
            EmpresaDtCriacao: true,
            EmpresaStatus: true,
            EmpresaEmail: true
        },
        orderBy: {
            EmpresaDtCriacao: 'desc'
        },
        take: 10
    });

    empresas.forEach(empresa => {
        cadastros.push({
            tipo: 'EMPRESA',
            id: empresa.EmpresaId,
            nome: empresa.EmpresaNome,
            dataCriacao: empresa.EmpresaDtCriacao,
            status: empresa.EmpresaStatus,
            email: empresa.EmpresaEmail
        });
    });

    // Últimos usuários cadastrados
    const usuarios = await prisma.usuario.findMany({
        select: {
            UsuarioId: true,
            UsuarioNome: true,
            UsuarioDtCriacao: true,
            UsuarioStatus: true,
            UsuarioTipo: true,
            UsuarioEmail: true
        },
        orderBy: {
            UsuarioDtCriacao: 'desc'
        },
        take: 10
    });

    usuarios.forEach(usuario => {
        cadastros.push({
            tipo: usuario.UsuarioTipo,
            id: usuario.UsuarioId,
            nome: usuario.UsuarioNome,
            dataCriacao: usuario.UsuarioDtCriacao,
            status: usuario.UsuarioStatus,
            email: usuario.UsuarioEmail
        });
    });

    // Ordenar por data mais recente
    cadastros.sort((a, b) => new Date(b.dataCriacao) - new Date(a.dataCriacao));

    return cadastros.slice(0, 20);
}

// 4. Quantidade de usuários por tipo e status
async function getQuantidadeUsuarios() {
    // Quantidade de empresas por status
    const empresasPorStatus = await prisma.empresa.groupBy({
        by: ['EmpresaStatus', 'EmpresaTipoCadastro'],
        _count: {
            EmpresaId: true
        }
    });

    // Quantidade de usuários por tipo e status
    const usuariosPorTipoStatus = await prisma.usuario.groupBy({
        by: ['UsuarioTipo', 'UsuarioStatus', 'UsuarioTipoCadastro'],
        _count: {
            UsuarioId: true
        }
    });

    // Organizar dados
    const empresas = {};
    empresasPorStatus.forEach(item => {
        empresas[item.EmpresaStatus] = item._count.EmpresaId;
    });

    // Organizar empresas por tipo de login
    const empresasPorTipoLogin = {};
    empresasPorStatus.forEach(item => {
        empresasPorTipoLogin[item.EmpresaTipoCadastro] = item._count.EmpresaId;
    });

    const clientes = {};
    const prestadores = {};

    usuariosPorTipoStatus.forEach(item => {
        if (item.UsuarioTipo === 'CLIENTE') {
            clientes[item.UsuarioStatus] = item._count.UsuarioId;
        } else if (item.UsuarioTipo === 'PRESTADOR') {
            prestadores[item.UsuarioStatus] = item._count.UsuarioId;
        }
    });

    // Organizar usuários por tipo de login
    const clientesPorTipoLogin = {};
    const prestadoresPorTipoLogin = {};

    usuariosPorTipoStatus.forEach(item => {
        if (item.UsuarioTipo === 'CLIENTE') {
            clientesPorTipoLogin[item.UsuarioTipoCadastro] = item._count.UsuarioId;
        } else if (item.UsuarioTipo === 'PRESTADOR') {
            prestadoresPorTipoLogin[item.UsuarioTipoCadastro] = item._count.UsuarioId;
        }
    });

    return {
        empresas: {
            total: Object.values(empresas).reduce((a, b) => a + b, 0),
            porStatus: empresas,
            porLogin: empresasPorTipoLogin
        },
        clientes: {
            total: Object.values(clientes).reduce((a, b) => a + b, 0),
            porStatus: clientes,
            porLogin: clientesPorTipoLogin
        },
        prestadores: {
            total: Object.values(prestadores).reduce((a, b) => a + b, 0),
            porStatus: prestadores,
            porLogin: prestadoresPorTipoLogin
        }
    };
}

// 5. Quantidade de estabelecimentos por empresa
async function getEstabelecimentosPorEmpresa() {
    const estabelecimentosPorEmpresa = await prisma.estabelecimento.groupBy({
        by: ['EmpresaId'],
        _count: {
            EstabelecimentoId: true
        }
    });

    const resultado = [];

    for (const item of estabelecimentosPorEmpresa) {
        const empresa = await prisma.empresa.findUnique({
            where: { EmpresaId: item.EmpresaId },
            select: { EmpresaNome: true }
        });

        if (empresa) {
            // Contar prestadores deste estabelecimento
            const prestadoresPorEstabelecimento = await prisma.usuarioEstabelecimento.groupBy({
                by: ['EstabelecimentoId'],
                _count: {
                    UsuarioId: true
                }
            });

            // Para cada estabelecimento, buscar os prestadores
            const estabelecimentos = await prisma.estabelecimento.findMany({
                where: { EmpresaId: item.EmpresaId },
                include: {
                    usuarios: {
                        include: {
                            usuario: {
                                select: { UsuarioTipo: true }
                            }
                        }
                    }
                }
            });

            let totalPrestadores = 0;
            estabelecimentos.forEach(estab => {
                const prestadoresCount = estab.usuarios.filter(
                    u => u.usuario.UsuarioTipo === 'PRESTADOR'
                ).length;
                totalPrestadores += prestadoresCount;
            });

            resultado.push({
                empresaId: item.EmpresaId,
                empresaNome: empresa.EmpresaNome,
                quantidadeEstabelecimentos: item._count.EstabelecimentoId,
                quantidadePrestadores: totalPrestadores
            });
        }
    }

    return resultado.sort((a, b) => b.quantidadeEstabelecimentos - a.quantidadeEstabelecimentos);
}

// 6. Quantidades de Agendamentos Criados e seus status
async function getAgendamentosStatus() {
    const agendamentosPorStatus = await prisma.agendamento.groupBy({
        by: ['AgendamentoStatus'],
        _count: {
            AgendamentoId: true
        }
    });

    const resultado = {};
    agendamentosPorStatus.forEach(item => {
        resultado[item.AgendamentoStatus] = item._count.AgendamentoId;
    });

    const total = Object.values(resultado).reduce((a, b) => a + b, 0);

    return {
        total,
        porStatus: resultado
    };
}

// 7. Quantidades de Agendamentos Criados (prestador exclusivo ou via estabelecimento)
async function getAgendamentosPorTipo() {
    // Agendamentos via estabelecimento (EstabelecimentoId não é null)
    const agendamentosViaEstabelecimento = await prisma.agendamento.count({
        where: {
            EstabelecimentoId: {
                not: null
            }
        }
    });

    // Agendamentos direto com prestador (EstabelecimentoId é null)
    const agendamentosDiretoPrestador = await prisma.agendamento.count({
        where: {
            EstabelecimentoId: null
        }
    });

    return {
        viaEstabelecimento: agendamentosViaEstabelecimento,
        diretoPrestador: agendamentosDiretoPrestador,
        total: agendamentosViaEstabelecimento + agendamentosDiretoPrestador
    };
}

// 8. Agendamentos iniciados por botões
async function getAgendamentosIniciadosPorBotao() {
    const botoes = {
        'AGENBTNPES': 'pesquisa',
        'AGENBTNCEN': 'botaoCentral',
        'AGENBTNTELA': 'botaoTela'
    };

    const resultado = {};

    for (const [acao, nome] of Object.entries(botoes)) {
        const quantidade = await prisma.log.count({
            where: {
                LogAcao: acao
            }
        });
        resultado[nome] = quantidade;
    }

    resultado.total = Object.values(resultado).reduce((a, b) => a + b, 0);

    return resultado;
}

// 9. Agendamentos iniciados vs finalizados
async function getAgendamentosFinalizacao() {
    // Buscar todos os logs de início de agendamento
    const acoesInicio = ['AGENBTNPES', 'AGENBTNCEN', 'AGENBTNTELA'];

    const logsInicio = await prisma.log.findMany({
        where: {
            LogAcao: {
                in: acoesInicio
            }
        },
        select: {
            LogDetalhe: true,
            LogData: true,
            LogAcao: true
        }
    });

    // Buscar todos os logs de finalização
    const logsFim = await prisma.log.findMany({
        where: {
            LogAcao: 'FIMAGEN'
        },
        select: {
            LogDetalhe: true
        }
    });

    // Criar conjunto de UUIDs finalizados
    const uuidsFinalizados = new Set();
    logsFim.forEach(log => {
        if (log.LogDetalhe) {
            uuidsFinalizados.add(log.LogDetalhe.trim());
        }
    });

    // Separar os inícios por tipo
    const iniciadosPorTipo = {
        pesquisa: [],
        botaoCentral: [],
        botaoTela: []
    };

    logsInicio.forEach(log => {
        let tipo = '';
        if (log.LogAcao === 'AGENBTNPES') tipo = 'pesquisa';
        else if (log.LogAcao === 'AGENBTNCEN') tipo = 'botaoCentral';
        else if (log.LogAcao === 'AGENBTNTELA') tipo = 'botaoTela';

        const uuid = log.LogDetalhe ? log.LogDetalhe.trim() : null;
        if (uuid) {
            iniciadosPorTipo[tipo].push({
                uuid,
                data: log.LogData
            });
        }
    });

    // Calcular estatísticas por tipo
    const resultado = {};
    let totalIniciados = 0;
    let totalFinalizados = 0;

    for (const [tipo, inicios] of Object.entries(iniciadosPorTipo)) {
        const quantidadeIniciados = inicios.length;
        const quantidadeFinalizados = inicios.filter(i => uuidsFinalizados.has(i.uuid)).length;
        const quantidadeNaoFinalizados = quantidadeIniciados - quantidadeFinalizados;

        totalIniciados += quantidadeIniciados;
        totalFinalizados += quantidadeFinalizados;

        resultado[tipo] = {
            iniciados: quantidadeIniciados,
            finalizados: quantidadeFinalizados,
            naoFinalizados: quantidadeNaoFinalizados,
            taxaFinalizacao: quantidadeIniciados > 0 ?
                ((quantidadeFinalizados / quantidadeIniciados) * 100).toFixed(2) + '%' : '0%'
        };
    }

    resultado.total = {
        iniciados: totalIniciados,
        finalizados: totalFinalizados,
        naoFinalizados: totalIniciados - totalFinalizados,
        taxaFinalizacao: totalIniciados > 0 ?
            ((totalFinalizados / totalIniciados) * 100).toFixed(2) + '%' : '0%'
    };

    return resultado;
}

// Método auxiliar para calcular inatividade
function calcularInatividade(ultimoLogin) {
    if (!ultimoLogin) return null;
    
    // Função para criar data sem timezone
    function parseLocalDate(dateInput) {
        if (dateInput instanceof Date) {
            return new Date(
                dateInput.getFullYear(),
                dateInput.getMonth(),
                dateInput.getDate(),
                dateInput.getHours(),
                dateInput.getMinutes(),
                dateInput.getSeconds()
            );
        }
        
        // Se for string, extrair componentes
        let dateStr = dateInput;
        if (dateStr.includes('Z')) {
            dateStr = dateStr.replace('Z', '');
        }
        
        const [datePart, timePart] = dateStr.split('T');
        const [year, month, day] = datePart.split('-');
        const [hour, minute, second = '0'] = (timePart || '00:00:00').split(':');
        
        return new Date(
            parseInt(year),
            parseInt(month) - 1,
            parseInt(day),
            parseInt(hour),
            parseInt(minute),
            parseInt(second.split('.')[0])
        );
    }
    
    const dataUltimoLogin = parseLocalDate(ultimoLogin);
    const agora = new Date();
    
    // Função para subtrair horas de uma data, ajustando dia/mês/ano
    function subtrairHoras(data, horasParaSubtrair) {
        let ano = data.getFullYear();
        let mes = data.getMonth();
        let dia = data.getDate();
        let hora = data.getHours();
        let minuto = data.getMinutes();
        let segundo = data.getSeconds();
        
        // Subtrair as horas
        hora -= horasParaSubtrair;
        
        // Ajustar se hora ficou negativa
        while (hora < 0) {
            hora += 24;
            dia -= 1;
            
            // Ajustar se dia ficou negativo
            if (dia < 1) {
                mes -= 1;
                
                // Ajustar se mês ficou negativo
                if (mes < 0) {
                    mes = 11;
                    ano -= 1;
                }
                
                // Obter último dia do mês anterior
                const ultimoDiaMes = new Date(ano, mes + 1, 0).getDate();
                dia = ultimoDiaMes;
            }
        }
        
        return new Date(ano, mes, dia, hora, minuto, segundo);
    }
    
    // Subtrair 3 horas da data atual
    const agoraAjustado = subtrairHoras(agora, 3);
    
    //console.log('Data do último login (local):', dataUltimoLogin);
    //console.log('Data atual original:', agora);
    //console.log('Data atual com -3h:', agoraAjustado);
    
    const diffMs = agoraAjustado.getTime() - dataUltimoLogin.getTime();
    const diffHoras = diffMs / (1000 * 60 * 60);
    
    if (diffHoras < 1) {
        const diffMinutos = Math.floor(diffMs / (1000 * 60));
        if (diffMinutos <= 0) {
            return 'agora mesmo';
        } else if (diffMinutos === 1) {
            return '1 minuto';
        } else {
            return `${diffMinutos} minutos`;
        }
    } else if (diffHoras < 24) {
        const horasInteiras = Math.floor(diffHoras);
        return horasInteiras === 1 ? '1 hora' : `${horasInteiras} horas`;
    } else if (diffHoras < 168) {
        const dias = Math.floor(diffHoras / 24);
        return dias === 1 ? '1 dia' : `${dias} dias`;
    } else {
        const semanas = Math.floor(diffHoras / 168);
        return semanas === 1 ? '1 semana' : `${semanas} semanas`;
    }
}

class UsuarioController {

    // Login do administrador
    async login(req, res) {
        try {
            const { AdministradorUsuario, AdministradorSenha } = req.body;

            if (!AdministradorUsuario || !AdministradorSenha) {
                return res.status(400).json({
                    error: 'Usuário e senha são obrigatórios'
                });
            }

            let usuarioSemSenha = null;
            let token = null;

            // Buscar na tabela Administrador
            let administrador = await prisma.administrador.findFirst({
                where: {
                    AdministradorUsuario: AdministradorUsuario.trim().toUpperCase()
                }
            });

            if (!administrador) {
                return res.status(403).json({
                    error: 'Usuário ou senha inválidos'
                });
            }

            // Verificar senha
            // Verificar senha (aplicando o pepper antes de comparar)
            const senhaComPepper = process.env.PEPPER_SENHA_ADMIN + AdministradorSenha.trim();
            const senhaValida = await bcrypt.compare(senhaComPepper, administrador.AdministradorSenha);

            if (!senhaValida) {
                return res.status(403).json({
                    error: 'Usuário ou senha inválidos'
                });
            }

            // Gerar token JWT
            token = jwt.sign(
                {
                    usuarioId: administrador.AdministradorId,
                    usuarioTipo: 'ADMINISTRADOR',
                    usuarioEmail: null
                },
                process.env.JWT_SECRET,
                { expiresIn: '24h' }
            );

            // Adaptar para o formato esperado pelo frontend (similar a Usuario)
            usuarioSemSenha = {
                AdministradorId: administrador.AdministradorId,
                AdministradorUsuario: administrador.AdministradorUsuario
            };

            // Atualizar último login
            const dataLocal = new Date();

            // Ajusta para o fuso de Brasília (UTC -3)
            const dataBrasilia = new Date(dataLocal.getTime() - (3 * 60 * 60 * 1000));

            await prisma.administrador.update({
                where: { AdministradorId: administrador.AdministradorId },
                data: { AdministradorUltimoLogin: dataBrasilia }
            });

            res.status(200).json({
                message: 'Login realizado com sucesso',
                token,
                usuario: usuarioSemSenha
            });

        } catch (error) {
            console.error('Erro no login:', error);
            res.status(500).json({
                error: 'Erro no login'
            });
        }
    }

    // Método principal que retorna todos os dados do dashboard
    async getDashboardData(req, res) {
        try {

            //console.log('Usuário autenticado:', req.usuario);
            if (req.usuario.usuarioTipo !== 'ADMINISTRADOR') {
                return res.status(403).json({
                    error: 'Erro ao acessar essa rota'
                });
            }

            const dashboardData = {};

            // 1. Últimos logins/acessos de usuário (inatividade)
            dashboardData.ultimosLogins = await getUltimosLogins();

            // 2. Últimas saídas/entradas dos usuários
            dashboardData.ultimasEntradasSaidas = await getUltimasEntradasSaidas();

            // 3. Últimos usuários cadastrados
            dashboardData.ultimosCadastros = await getUltimosCadastros();

            // 4. Quantidade de usuários por tipo e status
            dashboardData.quantidadeUsuarios = await getQuantidadeUsuarios();

            // 5. Quantidade de estabelecimentos por empresa e prestadores
            dashboardData.estabelecimentosPorEmpresa = await getEstabelecimentosPorEmpresa();

            // 6. Quantidades de Agendamentos Criados e seus status
            dashboardData.agendamentosStatus = await getAgendamentosStatus();

            // 7. Quantidades de Agendamentos Criados (prestador exclusivo ou via estabelecimento)
            dashboardData.agendamentosPorTipo = await getAgendamentosPorTipo();

            // 8. Agendamentos iniciados por botões
            dashboardData.agendamentosIniciadosPorBotao = await getAgendamentosIniciadosPorBotao();

            // 9. Agendamentos iniciados vs finalizados
            dashboardData.agendamentosFinalizacao = await getAgendamentosFinalizacao();

            res.status(200).json({
                success: true,
                data: dashboardData
            });

        } catch (error) {
            console.error('Erro ao buscar dados do dashboard:', error);
            res.status(500).json({
                success: false,
                error: 'Erro ao buscar dados do dashboard'
            });
        }
    }

}

module.exports = new UsuarioController();