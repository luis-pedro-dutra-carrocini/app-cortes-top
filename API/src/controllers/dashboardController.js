const prisma = require('../prisma.js');

function formatarHoras(disponibilidadesHoje) {
    // Calcular horas disponíveis hoje
    let horasDisponiveisHoje = 0;
    let minutosDisponiveisHoje = 0;

    disponibilidadesHoje.forEach(disp => {
        const horaInicio = disp.DisponibilidadeHoraInicio.split(':').map(Number);
        const horaFim = disp.DisponibilidadeHoraFim.split(':').map(Number);

        const minutosInicio = horaInicio[0] * 60 + horaInicio[1];
        const minutosFim = horaFim[0] * 60 + horaFim[1];

        const minutosDuracao = minutosFim - minutosInicio;
        minutosDisponiveisHoje += minutosDuracao;
        horasDisponiveisHoje += minutosDuracao / 60;
    });

    // Formatar para exibição (ex: "2h30min" ou "2.5h" ou "30min")
    let horasFormatadas = '';
    const horasInteiras = Math.floor(minutosDisponiveisHoje / 60);
    const minutosRestantes = minutosDisponiveisHoje % 60;

    if (horasInteiras > 0) {
        horasFormatadas = `${horasInteiras}h`;
        if (minutosRestantes > 0) {
            horasFormatadas += `${minutosRestantes}min`;
        }
    } else if (minutosRestantes > 0) {
        horasFormatadas = `${minutosRestantes}min`;
    } else {
        horasFormatadas = '0h';
    }

    return horasFormatadas;
}

class DashboardController {

    // Obter dados do dashboard para o prestador logado
    async obterDashboard(req, res) {
        try {
            const { tipo } = req.query; // 'ano', 'mes', 'dia'
            const prestadorId = req.usuario.usuarioId;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem acessar o dashboard'
                });
            }

            // Definir período com base no tipo
            const hoje = new Date();
            let dataInicio, dataFim;
            let agrupamento = '';

            switch (tipo) {
                case 'ano':
                    dataInicio = new Date(hoje.getFullYear(), 0, 0, 21, 0, 0); // 01/01/ano_atual
                    dataFim = new Date(hoje.getFullYear(), 11, 31, 20, 59, 59); // 31/12/ano_atual
                    agrupamento = 'ano';
                    break;
                case 'mes':
                    dataInicio = new Date(hoje.getFullYear(), hoje.getMonth(), 0, 21, 0, 0); // 01/mês_atual
                    dataFim = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0, 20, 59, 59); // último dia do mês
                    agrupamento = 'mês';
                    break;
                case 'dia':
                    dataInicio = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate() - 1, 21, 0, 0); // hoje
                    dataFim = new Date(hoje.getFullYear(), hoje.getMonth(), hoje.getDate(), 20, 59, 59); // hoje 23:59
                    agrupamento = 'dia';
                    break;
                default:
                    dataInicio = new Date(hoje.getFullYear(), hoje.getMonth(), 1); // padrão: mês atual
                    dataFim = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0);
                    agrupamento = 'mês';
            }

            console.log('dataInicio = ', dataInicio);
            console.log('dataFim = ', dataFim);

            // Buscar disponibilidades do prestador no período
            const disponibilidades = await prisma.disponibilidade.findMany({
                where: {
                    PrestadorId: prestadorId,
                    DisponibilidadeData: {
                        gte: dataInicio,
                        lte: dataFim
                    },
                }
            });

            console.log('disponibilidades = ', disponibilidades);

            // Buscar agendamentos do prestador no período
            const agendamentos = await prisma.agendamento.findMany({
                where: {
                    PrestadorId: prestadorId,
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
            let horasDisponiveis = 0;
            let horasReservadas = 0;
            let agendamentosPendentes = 0;
            let agendamentosAtendidos = 0;
            let agendamentosConcluidos = 0;
            let agendamentosConfirmados = 0;
            let agendamentosEmAndamento = 0;
            let agendamentosCancelados = 0;
            let faturamentoRealizado = 0;
            let faturamentoPrevisto = 0;

            // Calcular horas disponíveis
            disponibilidades.forEach(disp => {
                const horaInicio = disp.DisponibilidadeHoraInicio.split(':').map(Number);
                const horaFim = disp.DisponibilidadeHoraFim.split(':').map(Number);

                const minutosInicio = horaInicio[0] * 60 + horaInicio[1];
                const minutosFim = horaFim[0] * 60 + horaFim[1];

                if (disp.DisponibilidadeStatus) {
                    horasDisponiveis += (minutosFim - minutosInicio) / 60; // Converter para horas
                } else {
                    horasReservadas += (minutosFim - minutosInicio) / 60; // Converter para horas
                }

            });

            // Processar agendamentos
            agendamentos.forEach(ag => {
                const valor = parseFloat(ag.AgendamentoValorTotal);

                // Contagem por status
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
                }
            });

            agendamentosAtendidos = agendamentosConcluidos;

            // Calcular faturamento por período (para gráficos)
            const faturamentoPorPeriodo = [];

            if (tipo === 'ano') {
                // Agrupar por mês
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
                // Agrupar por semana ou dia (simplificado - por dia)
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
                // Agrupar por hora
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

            // Processar agendamentos
            for (const ag of agendamentos) {
                // Processar os serviços de cada agendamento
                for (const sa of ag.servicos) {
                    const servicoId = sa.servico.ServicoId;
                    const servicoValor = sa.ServicoValor;
                    const servicoNome = sa.servico.ServicoNome;

                    if (ag.AgendamentoStatus === 'CONCLUIDO') {
                        let estabelecimentoNome = '';

                        // Verificar se o serviço tem vínculo com estabelecimento
                        if (sa.servico.ServicoEstabelecimentoId !== null &&
                            sa.servico.ServicoEstabelecimentoId !== undefined) {
                            const estabelecimento = await prisma.estabelecimento.findUnique({
                                where: {
                                    EstabelecimentoId: sa.servico.ServicoEstabelecimentoId
                                },
                                select: {
                                    EstabelecimentoNome: true
                                }
                            });

                            if (estabelecimento && estabelecimento.EstabelecimentoNome) {
                                estabelecimentoNome = ` (${estabelecimento.EstabelecimentoNome})`;
                            }
                        }

                        if (!servicosMap.has(servicoId)) {
                            servicosMap.set(servicoId, {
                                id: servicoId,
                                nome: servicoNome + estabelecimentoNome,
                                quantidade: 0,
                                valorTotal: 0
                            });
                        }

                        const servico = servicosMap.get(servicoId);
                        servico.quantidade++;
                        servico.valorTotal = Number(servico.valorTotal) + Number(servicoValor);
                    }
                }
            }

            const servicosMaisSolicitados = Array.from(servicosMap.values())
                .sort((a, b) => b.quantidade - a.quantidade)
                .slice(0, 5)
                .map(s => ({
                    ...s,
                    valorTotal: parseFloat(s.valorTotal)
                }));

            // Preparar resposta
            const resposta = {
                prestadorId,
                periodo: {
                    tipo: agrupamento,
                    dataInicio,
                    dataFim
                },
                resumo: {
                    agendamentos: {
                        pendentes: agendamentosPendentes,
                        confirmados: agendamentosConfirmados,
                        emAndamento: agendamentosEmAndamento,
                        concluidos: agendamentosConcluidos,
                        atendidos: agendamentosAtendidos,
                        cancelados: agendamentosCancelados,
                        total: agendamentos.length
                    },
                    horasDisponiveis: parseFloat(horasDisponiveis.toFixed(2)),
                    horasReservadas: parseFloat(horasReservadas.toFixed(2)),
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

            //console.log('servicosMaisSolicitados = ', servicosMaisSolicitados);
            console.log('resposta = ', resposta);

            res.status(200).json({
                message: 'Dashboard carregado com sucesso',
                data: resposta
            });

        } catch (error) {
            console.error('Erro ao carregar dashboard:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Obter resumo rápido para o card da home
    async obterResumoRapido(req, res) {
        try {
            const prestadorId = req.usuario.usuarioId;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem acessar esta rota'
                });
            }

            // Obter data atual no fuso horário do Brasil usando Intl.DateTimeFormat
            const hoje = new Date();
            const formatter = new Intl.DateTimeFormat('pt-BR', {
                timeZone: 'America/Sao_Paulo',
                year: 'numeric',
                month: '2-digit',
                day: '2-digit'
            });

            const partes = formatter.formatToParts(hoje);
            const ano = partes.find(p => p.type === 'year').value;
            const mes = partes.find(p => p.type === 'month').value;
            const dia = partes.find(p => p.type === 'day').value;

            const dataString1 = `${ano}-${mes}-${dia - 1}`;
            const dataString2 = `${ano}-${mes}-${dia}`;

            // Criar datas no formato ISO com horário local
            const inicioHoje = new Date(`${dataString1}T21:00:00-03:00`);
            const fimHoje = new Date(`${dataString2}T20:59:59-03:00`);

            //console.log('Data string:', dataString);
            console.log('Início do dia:', inicioHoje.toISOString());
            console.log('Fim do dia:', fimHoje.toISOString());

            // Agendamentos de hoje
            const agendamentosHoje = await prisma.agendamento.findMany({
                where: {
                    PrestadorId: prestadorId,
                    AgendamentoDtServico: {
                        gte: inicioHoje,
                        lte: fimHoje
                    },
                    AgendamentoStatus: {
                        notIn: ['CANCELADO', 'CONCLUIDO']
                    }
                }
            });

            // Disponibilidades de hoje
            const disponibilidadesHojeDisp = await prisma.disponibilidade.findMany({
                where: {
                    PrestadorId: prestadorId,
                    DisponibilidadeData: {
                        gte: inicioHoje,
                        lte: fimHoje
                    },
                    DisponibilidadeStatus: true
                }
            });

            console.log('disponibilidadesHojeDisp = ', disponibilidadesHojeDisp);

            const horasFormatadasDisp = formatarHoras(disponibilidadesHojeDisp);

            // Disponibilidades de hoje
            const disponibilidadesHojeRes = await prisma.disponibilidade.findMany({
                where: {
                    PrestadorId: prestadorId,
                    DisponibilidadeData: {
                        gte: inicioHoje,
                        lte: fimHoje
                    },
                    DisponibilidadeStatus: false
                }
            });

            console.log('disponibilidadesHojeRes = ', disponibilidadesHojeRes);

            const horasFormatadasRes = formatarHoras(disponibilidadesHojeRes);

            // Faturamento do dia
            //const inicioMes = new Date(hoje.getFullYear(), hoje.getMonth(), 1);
            //const fimMes = new Date(hoje.getFullYear(), hoje.getMonth() + 1, 0, 23, 59, 59);

            const agendamentosDia = await prisma.agendamento.findMany({
                where: {
                    PrestadorId: prestadorId,
                    AgendamentoDtServico: {
                        gte: inicioHoje,
                        lte: fimHoje
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
                    horasReservadasHoje: horasFormatadasRes,
                    horasDisponiveisHoje: horasFormatadasDisp,
                    faturamentoDia: parseFloat(faturamentoDia.toFixed(2))
                }
            });

        } catch (error) {
            console.error('Erro ao carregar resumo rápido:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

}

module.exports = new DashboardController();