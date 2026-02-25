// src/controllers/disponibilidadeController.js
const prisma = require('../prisma.js');

function formatarData(data) {
    const dia = data.getDate().toString().padStart(2, '0');
    const mes = (data.getMonth() + 1).toString().padStart(2, '0');
    const ano = data.getFullYear();
    return `${dia}/${mes}/${ano}`;
}

class DisponibilidadeController {

    // Cadastrar disponibilidade (apenas PRESTADOR)
    async cadastrarDisponibilidade(req, res) {
        try {
            const {
                DisponibilidadeData,
                DisponibilidadeHoraInicio,
                DisponibilidadeHoraFim
            } = req.body;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem cadastrar disponibilidade'
                });
            }

            if (!DisponibilidadeHoraInicio || !DisponibilidadeHoraInicio.trim()) {
                return res.status(400).json({ error: 'Hora de início é obrigatória' });
            }

            if (!DisponibilidadeHoraFim || !DisponibilidadeHoraFim.trim()) {
                return res.status(400).json({ error: 'Hora de fim é obrigatória' });
            }

            // Validar formato de hora (HH:MM)
            const horaRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
            if (!horaRegex.test(DisponibilidadeHoraInicio)) {
                return res.status(400).json({ error: 'Hora de início deve estar no formato HH:MM (ex: 08:30)' });
            }
            if (!horaRegex.test(DisponibilidadeHoraFim)) {
                return res.status(400).json({ error: 'Hora de fim deve estar no formato HH:MM (ex: 18:00)' });
            }

            // Validar se hora fim é maior que hora início
            if (DisponibilidadeHoraFim <= DisponibilidadeHoraInicio) {
                return res.status(400).json({ error: 'Hora de fim deve ser maior que hora de início' });
            }

            // Verificar se já existe disponibilidade para este dia e horário
            const disponibilidadeExistente = await prisma.disponibilidade.findFirst({
                where: {
                    PrestadorId: req.usuario.usuarioId,
                    OR: [
                        {
                            AND: [
                                { DisponibilidadeData: new Date(DisponibilidadeData) },
                                { DisponibilidadeHoraInicio: { lte: DisponibilidadeHoraInicio } },
                                { DisponibilidadeHoraFim: { gt: DisponibilidadeHoraInicio } }
                            ]
                        },
                        {
                            AND: [
                                { DisponibilidadeData: new Date(DisponibilidadeData) },
                                { DisponibilidadeHoraInicio: { lt: DisponibilidadeHoraFim } },
                                { DisponibilidadeHoraFim: { gte: DisponibilidadeHoraFim } }
                            ]
                        }
                    ]
                }
            });

            if (disponibilidadeExistente) {
                return res.status(409).json({
                    error: 'Já existe uma disponibilidade cadastrada para este dia e horário'
                });
            }

            const DisponibilidadeDiaSemana = new Date(DisponibilidadeData).getDay(); // 0 (Domingo) a 6 (Sábado)

            // Criar disponibilidade
            const disponibilidade = await prisma.disponibilidade.create({
                data: {
                    PrestadorId: req.usuario.usuarioId,
                    DisponibilidadeData: new Date(DisponibilidadeData),
                    DisponibilidadeHoraInicio: DisponibilidadeHoraInicio.trim(),
                    DisponibilidadeHoraFim: DisponibilidadeHoraFim.trim(),
                    DisponibilidadeDiaSemana: DisponibilidadeDiaSemana
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    }
                }
            });

            // Adicionar descrição do dia da semana
            const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
            const respostaFormatada = {
                ...disponibilidade,
                dataFormatada: formatarData(disponibilidade.DisponibilidadeData),
                diaSemana: disponibilidade.DisponibilidadeData.getDay(),
                diaSemanaDescricao: diasSemana[disponibilidade.DisponibilidadeData.getDay()]
            };

            res.status(201).json({
                message: 'Disponibilidade cadastrada com sucesso',
                data: respostaFormatada
            });

        } catch (error) {
            console.error('Erro ao cadastrar disponibilidade:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Listar disponibilidades de um prestador (somente o pretador dono das disponibilidades)
    async listarDisponibilidadesPorPrestador(req, res) {
        try {
            const { prestadorId } = req.params;

            if (!prestadorId || isNaN(parseInt(prestadorId))) {
                return res.status(400).json({ error: 'ID de prestador inválido' });
            }

            // Verificar se o prestador existe
            const prestador = await prisma.usuario.findUnique({
                where: { UsuarioId: parseInt(prestadorId) }
            });

            if (!prestador) {
                return res.status(404).json({ error: 'Prestador não encontrado' });
            }

            if (prestador.UsuarioTipo !== 'PRESTADOR' || req.usuario.usuarioId !== parseInt(prestadorId)) {
                return res.status(403).json({
                    error: 'Apenas o prestador dono das disponibilidades pode acessar esta rota'
                });
            }

            if (prestador.UsuarioTipo !== 'PRESTADOR') {
                return res.status(400).json({ error: 'O usuário informado não é um prestador' });
            }

            // Buscar disponibilidades do prestador
            const disponibilidades = await prisma.disponibilidade.findMany({
                where: {
                    PrestadorId: parseInt(prestadorId)
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            //UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    }
                },
                orderBy: [
                    {
                        DisponibilidadeData: 'asc'
                    },
                    {
                        DisponibilidadeHoraInicio: 'asc'
                    }
                ]
            });

            const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

            // CORREÇÃO 1: Usar let ou var em vez de const
            let disponibilidadesFormatadas = disponibilidades.map(disp => ({
                ...disp,
                dataFormatada: formatarData(disp.DisponibilidadeData),
                diaSemana: disp.DisponibilidadeData.getDay(),
                diaSemanaDescricao: diasSemana[disp.DisponibilidadeData.getDay()]
            }));

            // Agrupar por data
            const disponibilidadesPorData = disponibilidadesFormatadas.reduce((acc, disp) => {
                const data = disp.DisponibilidadeData.toISOString().split('T')[0];
                if (!acc[data]) {
                    acc[data] = {
                        data: data,
                        dataFormatada: disp.dataFormatada,
                        diaSemana: disp.diaSemana,
                        diaSemanaDescricao: disp.diaSemanaDescricao,
                        disponibilidades: []
                    };
                }
                acc[data].disponibilidades.push(disp);
                return acc;
            }, {});

            // CORREÇÃO 2: Manter compatibilidade com frontend - retornar AMBOS os nomes
            res.status(200).json({
                data: disponibilidadesFormatadas,
                agrupadoPorData: Object.values(disponibilidadesPorData),
                agrupadoPorDia: Object.values(disponibilidadesPorData), // <- MESMO VALOR para compatibilidade
                prestador: {
                    id: prestador.UsuarioId,
                    nome: prestador.UsuarioNome
                }
            });

        } catch (error) {
            console.error('Erro ao listar disponibilidades:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Buscar disponibilidades de um prestador para uma data específica
    async listarDisponibilidadesPorPrestadorData(req, res) {
        try {
            const { prestadorId, data } = req.params;

            if (!prestadorId || isNaN(parseInt(prestadorId))) {
                return res.status(400).json({ error: 'ID de prestador inválido' });
            }

            if (!data) {
                return res.status(400).json({ error: 'Data é obrigatória' });
            }

            // Verificar se o prestador existe
            const prestador = await prisma.usuario.findUnique({
                where: { UsuarioId: parseInt(prestadorId) }
            });

            if (!prestador) {
                return res.status(404).json({ error: 'Prestador não encontrado' });
            }

            //Verificar se o usuário é CLIENTE
            if (req.usuario.usuarioTipo !== 'CLIENTE') {
                return res.status(403).json({
                    error: 'Apenas clientes podem acessar esta rota'
                });
            }

            if (prestador.UsuarioTipo !== 'PRESTADOR') {
                return res.status(400).json({ error: 'O usuário informado não é um prestador' });
            }

            // CORREÇÃO 1: Converter a data corretamente
            // A data vem no formato YYYY-MM-DD
            const dataParts = data.split('-');
            const ano = parseInt(dataParts[0]);
            const mes = parseInt(dataParts[1]) - 1; // Mês em JS é 0-based
            const dia = parseInt(dataParts[2]);

            // Criar data no início do dia (00:00:00)
            const dataInicio = new Date(ano, mes, dia, 0, 0, 0, 0);

            // Criar data no fim do dia (23:59:59)
            const dataFim = new Date(ano, mes, dia, 23, 59, 59, 999);

            // Buscar disponibilidades do prestador para a data específica
            const disponibilidades = await prisma.disponibilidade.findMany({
                where: {
                    PrestadorId: parseInt(prestadorId),
                    DisponibilidadeData: {
                        gte: dataInicio,
                        lte: dataFim
                    },
                    DisponibilidadeStatus: true // Apenas disponibilidades ativas
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioTelefone: true
                        }
                    }
                },
                orderBy: {
                    DisponibilidadeHoraInicio: 'asc'
                }
            });

            const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

            // CORREÇÃO 2: Usar let em vez de const para variáveis que podem ser modificadas
            let disponibilidadesFormatadas = disponibilidades.map(disp => {
                // Extrair apenas a hora do início (formato HH:MM)
                const horaInicio = disp.DisponibilidadeHoraInicio;

                return {
                    id: disp.DisponibilidadeId,
                    prestadorId: disp.PrestadorId,
                    horaInicio: horaInicio,
                    horaFim: disp.DisponibilidadeHoraFim,
                    status: disp.DisponibilidadeStatus,
                    data: disp.DisponibilidadeData,
                    dataFormatada: formatarData(disp.DisponibilidadeData),
                    diaSemana: disp.DisponibilidadeData.getDay(),
                    diaSemanaDescricao: diasSemana[disp.DisponibilidadeData.getDay()],
                    prestador: disp.prestador
                };
            });

            // CORREÇÃO 3: Formatar resposta para o frontend
            // O frontend espera uma lista de disponibilidades no formato do modelo
            console.log('Disponibilidades formatadas:', disponibilidadesFormatadas);
            res.status(200).json({
                success: true,
                data: disponibilidadesFormatadas,
                prestador: {
                    id: prestador.UsuarioId,
                    nome: prestador.UsuarioNome
                }
            });

        } catch (error) {
            console.error('Erro ao listar disponibilidades por data:', error);
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
    }


    // Buscar disponibilidade por ID (qualquer usuário logado)
    async buscarDisponibilidadeId(req, res) {
        try {
            const { disponibilidadeId } = req.params;

            if (!disponibilidadeId || isNaN(parseInt(disponibilidadeId))) {
                return res.status(400).json({ error: 'ID de disponibilidade inválido' });
            }

            const disponibilidade = await prisma.disponibilidade.findUnique({
                where: {
                    DisponibilidadeId: parseInt(disponibilidadeId),
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    }
                }
            });

            if (!disponibilidade) {
                return res.status(404).json({ error: 'Disponibilidade não encontrada' });
            }

            // Adicionar descrição do dia da semana
            const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
            const respostaFormatada = {
                ...disponibilidade,
                dataFormatada: formatarData(disponibilidade.DisponibilidadeData),
                diaSemana: disponibilidade.DisponibilidadeData.getDay(),
                diaSemanaDescricao: diasSemana[disponibilidade.DisponibilidadeData.getDay()]
            };

            res.status(200).json({ data: respostaFormatada });

        } catch (error) {
            console.error('Erro ao buscar disponibilidade:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Atualizar disponibilidade (apenas o PRESTADOR dono da disponibilidade)
    async atualizarDisponibilidade(req, res) {
        try {
            const disponibilidadeId = parseInt(req.params.id);
            const {
                DisponibilidadeData,
                DisponibilidadeHoraInicio,
                DisponibilidadeHoraFim
            } = req.body;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem atualizar disponibilidade'
                });
            }

            if (!disponibilidadeId || isNaN(parseInt(disponibilidadeId))) {
                return res.status(400).json({ error: 'ID de disponibilidade inválido' });
            }

            // Buscar a disponibilidade
            const disponibilidade = await prisma.disponibilidade.findUnique({
                where: { DisponibilidadeId: disponibilidadeId }
            });

            if (!disponibilidade) {
                return res.status(404).json({ error: 'Disponibilidade não encontrada' });
            }

            // Verificar se a disponibilidade pertence ao prestador logado
            if (disponibilidade.PrestadorId !== req.usuario.usuarioId) {
                return res.status(403).json({
                    error: 'Você só pode atualizar suas próprias disponibilidades'
                });
            }

            // CORREÇÃO: Verificar se a disponibilidade tem vínculo com agendamento ativo
            const agendamentoAtivo = await prisma.agendamento.findFirst({
                where: {
                    DisponibilidadeId: disponibilidadeId,
                    AgendamentoStatus: {
                        notIn: ['CANCELADO'] // Status que indicam que o agendamento ainda é relevante
                    }
                }
            });

            if (agendamentoAtivo) {
                return res.status(409).json({
                    error: 'Existe um agendamento ativo para este horário. Cancele o agendamento antes de atualizar a disponibilidade.'
                });
            }

            // CORREÇÃO: Validar se pelo menos um campo foi fornecido para atualização
            if (!DisponibilidadeData && !DisponibilidadeHoraInicio && !DisponibilidadeHoraFim) {
                return res.status(400).json({
                    error: 'Nenhum campo fornecido para atualização'
                });
            }

            // Preparar dados para atualização
            const dataFinal = DisponibilidadeData
                ? new Date(DisponibilidadeData)
                : disponibilidade.DisponibilidadeData;

            const horaInicioFinal = DisponibilidadeHoraInicio || disponibilidade.DisponibilidadeHoraInicio;
            const horaFimFinal = DisponibilidadeHoraFim || disponibilidade.DisponibilidadeHoraFim;

            // Validar formato de hora (HH:MM) apenas se foram fornecidos
            const horaRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;

            if (DisponibilidadeHoraInicio && !horaRegex.test(DisponibilidadeHoraInicio)) {
                return res.status(400).json({ error: 'Hora de início deve estar no formato HH:MM (ex: 08:30)' });
            }

            if (DisponibilidadeHoraFim && !horaRegex.test(DisponibilidadeHoraFim)) {
                return res.status(400).json({ error: 'Hora de fim deve estar no formato HH:MM (ex: 18:00)' });
            }

            // Validar se hora fim é maior que hora início (considerando valores atuais ou novos)
            if (horaFimFinal <= horaInicioFinal) {
                return res.status(400).json({ error: 'Hora de fim deve ser maior que hora de início' });
            }

            // Validar se a data é futura (opcional, depende da regra de negócio)
            const hoje = new Date();
            hoje.setHours(0, 0, 0, 0);

            if (DisponibilidadeData && dataFinal < hoje) {
                return res.status(400).json({ error: 'A data da disponibilidade deve ser futura' });
            }

            // CORREÇÃO: Verificar conflito com outras disponibilidades (excluindo a atual)
            const conflito = await prisma.disponibilidade.findFirst({
                where: {
                    DisponibilidadeId: { not: disponibilidadeId },
                    PrestadorId: req.usuario.usuarioId,
                    DisponibilidadeData: dataFinal,
                    OR: [
                        {
                            AND: [
                                { DisponibilidadeHoraInicio: { lte: horaInicioFinal } },
                                { DisponibilidadeHoraFim: { gt: horaInicioFinal } }
                            ]
                        },
                        {
                            AND: [
                                { DisponibilidadeHoraInicio: { lt: horaFimFinal } },
                                { DisponibilidadeHoraFim: { gte: horaFimFinal } }
                            ]
                        },
                        {
                            AND: [
                                { DisponibilidadeHoraInicio: { gte: horaInicioFinal } },
                                { DisponibilidadeHoraFim: { lte: horaFimFinal } }
                            ]
                        }
                    ]
                }
            });

            if (conflito) {
                return res.status(409).json({
                    error: 'Conflito com outra disponibilidade existente para este dia e horário'
                });
            }

            // Atualizar disponibilidade
            const disponibilidadeAtualizada = await prisma.disponibilidade.update({
                where: {
                    DisponibilidadeId: disponibilidadeId
                },
                data: {
                    DisponibilidadeData: dataFinal,
                    DisponibilidadeHoraInicio: horaInicioFinal,
                    DisponibilidadeHoraFim: horaFimFinal
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    }
                }
            });

            // Adicionar formatação para resposta
            const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
            const respostaFormatada = {
                ...disponibilidadeAtualizada,
                dataFormatada: formatarData(disponibilidadeAtualizada.DisponibilidadeData),
                diaSemana: disponibilidadeAtualizada.DisponibilidadeData.getDay(),
                diaSemanaDescricao: diasSemana[disponibilidadeAtualizada.DisponibilidadeData.getDay()]
            };

            res.status(200).json({
                message: 'Disponibilidade atualizada com sucesso',
                data: respostaFormatada
            });

        } catch (error) {
            console.error('Erro ao atualizar disponibilidade:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }

    // Excluir disponibilidade
    async excluirDisponibilidade(req, res) {
        try {
            const disponibilidadeId = parseInt(req.params.disponibilidadeId);

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({
                    error: 'Apenas prestadores podem excluir disponibilidade'
                });
            }

            if (!disponibilidadeId || isNaN(parseInt(disponibilidadeId))) {
                return res.status(400).json({ error: 'ID de disponibilidade inválido' });
            }

            // Buscar a disponibilidade
            const disponibilidade = await prisma.disponibilidade.findUnique({
                where: { DisponibilidadeId: disponibilidadeId }
            });

            if (!disponibilidade) {
                return res.status(404).json({ error: 'Disponibilidade não encontrada' });
            }

            // Verificar se a disponibilidade pertence ao prestador logado
            if (disponibilidade.PrestadorId !== req.usuario.usuarioId) {
                return res.status(403).json({
                    error: 'Você só pode excluir suas próprias disponibilidades'
                });
            }

            // Verificar se existem agendamentos ativos
            const agendamentoAtivo = await prisma.agendamento.findFirst({
                where: {
                    DisponibilidadeId: disponibilidadeId,
                    AgendamentoStatus: {
                        notIn: ['CANCELADO', 'CONCLUIDO']
                    }
                }
            });

            if (agendamentoAtivo) {
                return res.status(409).json({
                    error: 'Existe um agendamento ativo para este horário. Cancele o agendamento antes de excluir a disponibilidade.'
                });
            }

            // Opção 1: Excluir permanentemente (se não houver histórico)
            const agendamentosHistorico = await prisma.agendamento.count({
                where: {
                    DisponibilidadeId: disponibilidadeId
                }
            });

            if (agendamentosHistorico > 0) {
                // Opção 2: Apenas desativar em vez de excluir
                await prisma.disponibilidade.update({
                    where: { DisponibilidadeId: disponibilidadeId },
                    data: { DisponibilidadeStatus: false }
                });

                return res.status(200).json({
                    message: 'Disponibilidade desativada com sucesso'
                });
            } else {
                // Excluir permanentemente se não houver histórico
                await prisma.disponibilidade.delete({
                    where: { DisponibilidadeId: disponibilidadeId }
                });

                return res.status(200).json({
                    message: 'Disponibilidade excluída com sucesso'
                });
            }

        } catch (error) {
            console.error('Erro ao excluir disponibilidade:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // Buscar disponibilidades por data específica
    async buscarDisponibilidadesPorData(req, res) {
        try {
            const { data } = req.params; // Formato esperado: YYYY-MM-DD

            if (!data) {
                return res.status(400).json({ error: 'Data é obrigatória' });
            }

            const dataBusca = new Date(data);

            // Ajustar para o início e fim do dia
            const inicioDia = new Date(dataBusca);
            inicioDia.setHours(0, 0, 0, 0);

            const fimDia = new Date(dataBusca);
            fimDia.setHours(23, 59, 59, 999);

            // Buscar disponibilidades para a data específica
            const disponibilidades = await prisma.disponibilidade.findMany({
                where: {
                    DisponibilidadeData: {
                        gte: inicioDia,
                        lte: fimDia
                    }
                },
                include: {
                    prestador: {
                        select: {
                            UsuarioId: true,
                            UsuarioNome: true,
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    }
                },
                orderBy: [
                    {
                        PrestadorId: 'asc'
                    },
                    {
                        DisponibilidadeHoraInicio: 'asc'
                    }
                ]
            });

            const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];

            // Formatar disponibilidades
            const disponibilidadesFormatadas = disponibilidades.map(disp => ({
                ...disp,
                dataFormatada: formatarData(disp.DisponibilidadeData),
                diaSemana: disp.DisponibilidadeData.getDay(),
                diaSemanaDescricao: diasSemana[disp.DisponibilidadeData.getDay()]
            }));

            // Agrupar por prestador
            const disponibilidadesPorPrestador = disponibilidadesFormatadas.reduce((acc, disp) => {
                const prestadorId = disp.PrestadorId;
                if (!acc[prestadorId]) {
                    acc[prestadorId] = {
                        prestador: disp.prestador,
                        disponibilidades: []
                    };
                }
                acc[prestadorId].disponibilidades.push(disp);
                return acc;
            }, {});

            res.status(200).json({
                data: disponibilidadesFormatadas,
                agrupadoPorPrestador: Object.values(disponibilidadesPorPrestador),
                data: {
                    original: data,
                    formatada: formatarData(dataBusca),
                    diaSemana: dataBusca.getDay(),
                    diaSemanaDescricao: diasSemana[dataBusca.getDay()]
                }
            });

        } catch (error) {
            console.error('Erro ao buscar disponibilidades por data:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }
}

module.exports = new DisponibilidadeController();