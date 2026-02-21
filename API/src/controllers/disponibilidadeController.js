// src/controllers/disponibilidadeController.js
const prisma = require('../prisma.js');

class DisponibilidadeController {

    // Cadastrar disponibilidade (apenas PRESTADOR)
    async cadastrarDisponibilidade(req, res) {
        try {
            const {
                DisponibilidadeDiaSemana,
                DisponibilidadeHoraInicio,
                DisponibilidadeHoraFim
            } = req.body;

            // Verificar se o usuário é PRESTADOR
            if (req.usuario.usuarioTipo !== 'PRESTADOR') {
                return res.status(403).json({ 
                    error: 'Apenas prestadores podem cadastrar disponibilidade' 
                });
            }

            // Validações
            if (DisponibilidadeDiaSemana === undefined || DisponibilidadeDiaSemana === null) {
                return res.status(400).json({ error: 'Dia da semana é obrigatório' });
            }

            if (DisponibilidadeDiaSemana < 0 || DisponibilidadeDiaSemana > 6) {
                return res.status(400).json({ error: 'Dia da semana deve ser entre 0 (Domingo) e 6 (Sábado)' });
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
                    DisponibilidadeDiaSemana: DisponibilidadeDiaSemana,
                    OR: [
                        {
                            AND: [
                                { DisponibilidadeHoraInicio: { lte: DisponibilidadeHoraInicio } },
                                { DisponibilidadeHoraFim: { gt: DisponibilidadeHoraInicio } }
                            ]
                        },
                        {
                            AND: [
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

            // Criar disponibilidade
            const disponibilidade = await prisma.disponibilidade.create({
                data: {
                    PrestadorId: req.usuario.usuarioId,
                    DisponibilidadeDiaSemana: parseInt(DisponibilidadeDiaSemana),
                    DisponibilidadeHoraInicio: DisponibilidadeHoraInicio.trim(),
                    DisponibilidadeHoraFim: DisponibilidadeHoraFim.trim()
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
                DisponibilidadeDiaSemanaDescricao: diasSemana[disponibilidade.DisponibilidadeDiaSemana]
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

    // Listar disponibilidades de um prestador (qualquer usuário logado)
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
                            UsuarioEmail: true,
                            UsuarioTelefone: true
                        }
                    }
                },
                orderBy: [
                    {
                        DisponibilidadeDiaSemana: 'asc'
                    },
                    {
                        DisponibilidadeHoraInicio: 'asc'
                    }
                ]
            });

            // Adicionar descrição do dia da semana e agrupar por dia
            const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
            
            const disponibilidadesFormatadas = disponibilidades.map(disp => ({
                ...disp,
                DisponibilidadeDiaSemanaDescricao: diasSemana[disp.DisponibilidadeDiaSemana]
            }));

            // Agrupar por dia da semana para facilitar visualização
            const disponibilidadesPorDia = disponibilidadesFormatadas.reduce((acc, disp) => {
                const dia = disp.DisponibilidadeDiaSemana;
                if (!acc[dia]) {
                    acc[dia] = {
                        dia: dia,
                        diaDescricao: diasSemana[dia],
                disponibilidades: []
                    };
                }
                acc[dia].disponibilidades.push(disp);
                return acc;
            }, {});

            res.status(200).json({ 
                data: disponibilidadesFormatadas,
                agrupadoPorDia: Object.values(disponibilidadesPorDia),
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

    // Buscar disponibilidade por ID (qualquer usuário logado)
    async buscarDisponibilidadeId(req, res) {
        try {
            const { disponibilidadeId } = req.params;

            if (!disponibilidadeId || isNaN(parseInt(disponibilidadeId))) {
                return res.status(400).json({ error: 'ID de disponibilidade inválido' });
            }

            const disponibilidade = await prisma.disponibilidade.findUnique({
                where: {
                    Disponibilidadeid: parseInt(disponibilidadeId)
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
                DisponibilidadeDiaSemanaDescricao: diasSemana[disponibilidade.DisponibilidadeDiaSemana]
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
                DisponibilidadeDiaSemana,
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
                where: { Disponibilidadeid: disponibilidadeId }
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

            // Validações básicas
            const diaSemanaFinal = DisponibilidadeDiaSemana !== undefined ? DisponibilidadeDiaSemana : disponibilidade.DisponibilidadeDiaSemana;
            const horaInicioFinal = DisponibilidadeHoraInicio || disponibilidade.DisponibilidadeHoraInicio;
            const horaFimFinal = DisponibilidadeHoraFim || disponibilidade.DisponibilidadeHoraFim;

            if (diaSemanaFinal < 0 || diaSemanaFinal > 6) {
                return res.status(400).json({ error: 'Dia da semana deve ser entre 0 (Domingo) e 6 (Sábado)' });
            }

            // Validar formato de hora (HH:MM)
            const horaRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;
            if (!horaRegex.test(horaInicioFinal)) {
                return res.status(400).json({ error: 'Hora de início deve estar no formato HH:MM (ex: 08:30)' });
            }
            if (!horaRegex.test(horaFimFinal)) {
                return res.status(400).json({ error: 'Hora de fim deve estar no formato HH:MM (ex: 18:00)' });
            }

            // Validar se hora fim é maior que hora início
            if (horaFimFinal <= horaInicioFinal) {
                return res.status(400).json({ error: 'Hora de fim deve ser maior que hora de início' });
            }

            // Verificar conflito com outras disponibilidades (excluindo a atual)
            const conflito = await prisma.disponibilidade.findFirst({
                where: {
                    Disponibilidadeid: { not: disponibilidadeId },
                    PrestadorId: req.usuario.usuarioId,
                    DisponibilidadeDiaSemana: diaSemanaFinal,
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
                    Disponibilidadeid: disponibilidadeId
                },
                data: {
                    DisponibilidadeDiaSemana: diaSemanaFinal,
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

            // Adicionar descrição do dia da semana
            const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
            const respostaFormatada = {
                ...disponibilidadeAtualizada,
                DisponibilidadeDiaSemanaDescricao: diasSemana[disponibilidadeAtualizada.DisponibilidadeDiaSemana]
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

    // Excluir disponibilidade (apenas o PRESTADOR dono da disponibilidade)
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
                where: { Disponibilidadeid: disponibilidadeId }
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

            // Excluir disponibilidade
            await prisma.disponibilidade.delete({
                where: {
                    Disponibilidadeid: disponibilidadeId
                }
            });

            res.status(200).json({
                message: 'Disponibilidade excluída com sucesso'
            });

        } catch (error) {
            console.error('Erro ao excluir disponibilidade:', error);
            res.status(500).json({ error: error.message });
        }
    }

    // Buscar disponibilidades por dia da semana (qualquer usuário logado)
    async buscarDisponibilidadesPorDia(req, res) {
        try {
            const { diaSemana } = req.params;

            if (diaSemana === undefined || diaSemana === null) {
                return res.status(400).json({ error: 'Dia da semana é obrigatório' });
            }

            const dia = parseInt(diaSemana);
            if (dia < 0 || dia > 6) {
                return res.status(400).json({ error: 'Dia da semana deve ser entre 0 (Domingo) e 6 (Sábado)' });
            }

            // Buscar disponibilidades para o dia específico
            const disponibilidades = await prisma.disponibilidade.findMany({
                where: {
                    DisponibilidadeDiaSemana: dia
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

            // Adicionar descrição do dia da semana
            const diasSemana = ['Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado'];
            
            const disponibilidadesFormatadas = disponibilidades.map(disp => ({
                ...disp,
                DisponibilidadeDiaSemanaDescricao: diasSemana[disp.DisponibilidadeDiaSemana]
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
                dia: {
                    numero: dia,
                    descricao: diasSemana[dia]
                }
            });

        } catch (error) {
            console.error('Erro ao buscar disponibilidades por dia:', error);
            res.status(500).json({
                error: error.message
            });
        }
    }
}

module.exports = new DisponibilidadeController();