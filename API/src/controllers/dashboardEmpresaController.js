const prisma = require('../prisma.js');

function formatarHoras(disponibilidades) {
    let totalMinutos = 0;
    disponibilidades.forEach(disp => {
        const [horaInicio, minInicio] = disp.DisponibilidadeHoraInicio.split(':').map(Number);
        const [horaFim, minFim] = disp.DisponibilidadeHoraFim.split(':').map(Number);
        const minutosInicio = horaInicio * 60 + minInicio;
        const minutosFim = horaFim * 60 + minFim;
        totalMinutos += minutosFim - minutosInicio;
    });
    const horas = totalMinutos / 60;
    const horasInteiras = Math.floor(horas);
    const minutos = Math.round((horas - horasInteiras) * 60);
    if (minutos > 0) {
        return `${horasInteiras}h${minutos}min`;
    }
    return `${horasInteiras}h`;
}

class DashboardEmpresaController {

    // Obter dados do dashboard para a empresa logada
    async obterDashboardEmpresa(req, res) {
        try {
            const { tipo, estabelecimentoId } = req.query; // 'ano', 'mes', 'dia'
            const empresaId = req.usuario.usuarioId;

            // Verificar se o usuário é EMPRESA
            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem acessar o dashboard'
                });
            }

            // Definir período com base no tipo
            const hoje = new Date();
            let dataInicio, dataFim;
            let agrupamento = '';

            switch (tipo) {
                case 'ano':
                    dataInicio = new Date(hoje.getFullYear(), 0, 1, 0, 0, 0);
                    dataFim = new Date(hoje.getFullYear(), 11, 31, 23, 59, 59);
                    agrupamento = 'ano';
                    break;
                case 'mes':
                    dataInicio = new Date(hoje.getFullYear(), hoje.getMonth(), 1, 0, 0, 0);
                    dataFim = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0, 23, 59, 59);
                    agrupamento = 'mês';
                    break;
                case 'dia':
                    dataInicio = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate(), 0, 0, 0);
                    dataFim = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate(), 23, 59, 59);
                    agrupamento = 'dia';
                    break;
                default:
                    dataInicio = new Date(hoje.getFullYear(), hoje.getMonth(), 1);
                    dataFim = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0);
                    agrupamento = 'mês';
            }

            // Construir filtro de estabelecimento
            const whereEstabelecimentos = {
                EmpresaId: empresaId
            };
            if (estabelecimentoId) {
                whereEstabelecimentos.EstabelecimentoId = parseInt(estabelecimentoId);
            }

            // Buscar estabelecimentos da empresa
            const estabelecimentos = await prisma.estabelecimento.findMany({
                where: whereEstabelecimentos
            });

            const estabelecimentoIds = estabelecimentos.map(e => e.EstabelecimentoId);

            // Buscar agendamentos dos estabelecimentos no período
            const agendamentos = await prisma.agendamento.findMany({
                where: {
                    EstabelecimentoId: { in: estabelecimentoIds },
                    AgendamentoDtServico: {
                        gte: dataInicio,
                        lte: dataFim
                    }
                },
                include: {
                    servicos: {
                        include: {
                            servico: true
                        }
                    }
                },
                orderBy: {
                    AgendamentoDtServico: 'asc'
                }
            });

            // Calcular estatísticas
            let agendamentosPendentes = 0;
            let agendamentosConfirmados = 0;
            let agendamentosEmAndamento = 0;
            let agendamentosConcluidos = 0;
            let agendamentosCancelados = 0;
            let agendamentosRecusados = 0;
            let faturamentoRealizado = 0;
            let faturamentoPrevisto = 0;

            // Processar agendamentos
            agendamentos.forEach(ag => {
                const valor = parseFloat(ag.AgendamentoValorTotal);

                switch (ag.AgendamentoStatus) {
                    case 'PENDENTE':
                        agendamentosPendentes++;
                        faturamentoPrevisto += valor;
                        break;
                    case 'CONFIRMADO':
                        agendamentosConfirmados++;
                        faturamentoPrevisto += valor;
                        break;
                    case 'EM_ANDAMENTO':
                        agendamentosEmAndamento++;
                        faturamentoPrevisto += valor;
                        break;
                    case 'CONCLUIDO':
                        agendamentosConcluidos++;
                        faturamentoRealizado += valor;
                        break;
                    case 'CANCELADO':
                        agendamentosCancelados++;
                        break;
                    case 'RECUSADO':
                        agendamentosRecusados++;
                        break;
                }
            });

            // Calcular faturamento por período (para gráficos)
            const faturamentoPorPeriodo = [];

            if (tipo === 'ano') {
                for (let mes = 0; mes < 12; mes++) {
                    const agendamentosMes = agendamentos.filter(ag => {
                        const dataAg = new Date(ag.AgendamentoDtServico);
                        return dataAg.getMonth() === mes;
                    });
                    const valorMes = agendamentosMes.reduce((acc, ag) => {
                        if (ag.AgendamentoStatus === 'CONCLUIDO') {
                            return acc + parseFloat(ag.AgendamentoValorTotal);
                        }
                        return acc;
                    }, 0);
                    faturamentoPorPeriodo.push({
                        periodo: `${mes + 1}`,
                        valor: valorMes
                    });
                }
            } else if (tipo === 'mes') {
                const diasNoMes = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0).getDate();
                for (let dia = 1; dia <= diasNoMes; dia++) {
                    const agendamentosDia = agendamentos.filter(ag => {
                        const dataAg = new Date(ag.AgendamentoDtServico);
                        return dataAg.getDate() === dia;
                    });
                    const valorDia = agendamentosDia.reduce((acc, ag) => {
                        if (ag.AgendamentoStatus === 'CONCLUIDO') {
                            return acc + parseFloat(ag.AgendamentoValorTotal);
                        }
                        return acc;
                    }, 0);
                    faturamentoPorPeriodo.push({
                        periodo: `${dia}`,
                        valor: valorDia
                    });
                }
            } else if (tipo === 'dia') {
                for (let hora = 0; hora < 24; hora++) {
                    const agendamentosHora = agendamentos.filter(ag => {
                        const horaAg = parseInt(ag.AgendamentoHoraServico.split(':')[0]);
                        return horaAg === hora;
                    });
                    const valorHora = agendamentosHora.reduce((acc, ag) => {
                        if (ag.AgendamentoStatus === 'CONCLUIDO') {
                            return acc + parseFloat(ag.AgendamentoValorTotal);
                        }
                        return acc;
                    }, 0);
                    faturamentoPorPeriodo.push({
                        periodo: `${hora.toString().padStart(2, '0')}:00`,
                        valor: valorHora
                    });
                }
            }

            // Serviços mais solicitados
            const servicosMap = new Map();
            agendamentos.forEach(ag => {
                ag.servicos.forEach(sa => {
                    const servicoId = sa.servico.ServicoId;
                    const servicoNome = sa.servico.ServicoNome;
                    if (ag.AgendamentoStatus === 'CONCLUIDO') {
                        if (!servicosMap.has(servicoId)) {
                            servicosMap.set(servicoId, {
                                id: servicoId,
                                nome: servicoNome,
                                quantidade: 0,
                                valorTotal: 0
                            });
                        }
                        const servico = servicosMap.get(servicoId);
                        servico.quantidade++;
                        servico.valorTotal += parseFloat(sa.ServicoValor);
                    }
                });
            });

            const servicosMaisSolicitados = Array.from(servicosMap.values())
                .sort((a, b) => b.quantidade - a.quantidade)
                .slice(0, 5)
                .map(s => ({
                    ...s,
                    valorTotal: parseFloat(s.valorTotal.toFixed(2))
                }));

            // Preparar resposta
            const resposta = {
                empresaId,
                periodo: {
                    tipo: agrupamento,
                    dataInicio,
                    dataFim
                },
                estabelecimentos: estabelecimentos.map(e => ({
                    id: e.EstabelecimentoId,
                    nome: e.EstabelecimentoNome
                })),
                resumo: {
                    agendamentos: {
                        pendentes: agendamentosPendentes,
                        confirmados: agendamentosConfirmados,
                        emAndamento: agendamentosEmAndamento,
                        concluidos: agendamentosConcluidos,
                        cancelados: agendamentosCancelados,
                        recusados: agendamentosRecusados,
                        total: agendamentos.length
                    },
                    faturamento: {
                        realizado: parseFloat(faturamentoRealizado.toFixed(2)),
                        previsto: parseFloat(faturamentoPrevisto.toFixed(2)),
                        total: parseFloat((faturamentoRealizado + faturamentoPrevisto).toFixed(2))
                    }
                },
                detalhamento: {
                    faturamentoPorPeriodo,
                    servicosMaisSolicitados
                }
            };

            res.status(200).json({
                message: 'Dashboard carregado com sucesso',
                data: resposta
            });

        } catch (error) {
            console.error('Erro ao carregar dashboard da empresa:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Obter resumo rápido para o card da home da empresa
    async obterResumoRapidoEmpresa(req, res) {
        try {
            const empresaId = req.usuario.usuarioId;

            if (req.usuario.usuarioTipo !== 'EMPRESA') {
                return res.status(403).json({
                    error: 'Apenas empresas podem acessar esta rota'
                });
            }

            const hoje = new Date();
            const inicioDia = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate(), 0, 0, 0);
            const fimDia = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate(), 23, 59, 59);

            // Buscar estabelecimentos da empresa
            const estabelecimentos = await prisma.estabelecimento.findMany({
                where: { EmpresaId: empresaId },
                select: { EstabelecimentoId: true }
            });

            const estabelecimentoIds = estabelecimentos.map(e => e.EstabelecimentoId);

            // Agendamentos de hoje
            const agendamentosHoje = await prisma.agendamento.findMany({
                where: {
                    EstabelecimentoId: { in: estabelecimentoIds },
                    AgendamentoDtServico: {
                        gte: inicioDia,
                        lte: fimDia
                    },
                    AgendamentoStatus: {
                        notIn: ['CANCELADO', 'CONCLUIDO']
                    }
                }
            });

            // Faturamento do dia
            const agendamentosDia = await prisma.agendamento.findMany({
                where: {
                    EstabelecimentoId: { in: estabelecimentoIds },
                    AgendamentoDtServico: {
                        gte: inicioDia,
                        lte: fimDia
                    },
                    AgendamentoStatus: 'CONCLUIDO'
                }
            });

            const faturamentoDia = agendamentosDia.reduce((acc, ag) =>
                acc + parseFloat(ag.AgendamentoValorTotal), 0
            );

            res.status(200).json({
                data: {
                    agendamentosHoje: agendamentosHoje.length,
                    estabelecimentosAtivos: estabelecimentos.length,
                    faturamentoDia: parseFloat(faturamentoDia.toFixed(2))
                }
            });

        } catch (error) {
            console.error('Erro ao carregar resumo rápido da empresa:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

}

module.exports = new DashboardEmpresaController();