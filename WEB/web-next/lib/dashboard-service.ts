// lib/dashboard-service.ts

import { apiClient } from "./api"

export interface DashboardData {
  ultimosLogins: Array<{
    tipo: string
    id: number
    nome: string
    ultimoLogin: string
    status: string
    inativo: string | null
    email: string
  }>
  ultimasEntradasSaidas: Array<{
    acao: string
    nome: string
    tipoRelacao: string
    data: string
    detalhe: string
    email: string
  }>
  ultimosCadastros: Array<{
    tipo: string
    id: number
    nome: string
    dataCriacao: string
    status: string
    email: string
  }>
  quantidadeUsuarios: {
    empresas: {
      total: number
      porStatus: Record<string, number>
      porLogin: Record<string, number>
    }
    clientes: {
      total: number
      porStatus: Record<string, number>
      porLogin: Record<string, number>
    }
    prestadores: {
      total: number
      porStatus: Record<string, number>
      porLogin: Record<string, number>
    }
  }
  estabelecimentosPorEmpresa: Array<{
    empresaId: number
    empresaNome: string
    quantidadeEstabelecimentos: number
    quantidadePrestadores: number
  }>
  agendamentosStatus: {
    total: number
    porStatus: Record<string, number>
  }
  agendamentosPorTipo: {
    viaEstabelecimento: number
    diretoPrestador: number
    total: number
  }
  agendamentosIniciadosPorBotao: {
    pesquisa: number
    botaoCentral: number
    botaoTela: number
    total: number
  }
  agendamentosFinalizacao: {
    pesquisa: {
      iniciados: number
      finalizados: number
      naoFinalizados: number
      taxaFinalizacao: string
    }
    botaoCentral: {
      iniciados: number
      finalizados: number
      naoFinalizados: number
      taxaFinalizacao: string
    }
    botaoTela: {
      iniciados: number
      finalizados: number
      naoFinalizados: number
      taxaFinalizacao: string
    }
    total: {
      iniciados: number
      finalizados: number
      naoFinalizados: number
      taxaFinalizacao: string
    }
  }
}

export async function getDashboardData(): Promise<DashboardData> {
  try {
    const response = await apiClient.get('/admin/dashboard')
    return response.data.data
  } catch (error) {
    console.error('Erro ao buscar dados do dashboard:', error)
    throw error
  }
}